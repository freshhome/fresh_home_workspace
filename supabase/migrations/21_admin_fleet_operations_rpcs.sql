-- ==============================================================================
-- Fresh Home: Admin Fleet Operations Dashboard RPCs (Phase 5)
-- Description: Analytics and operational control functions for the Admin app.
-- Depends on: 04_assignment_system.sql, 10_smart_assignment.sql, 12_capacity_overrides.sql
-- ==============================================================================


-- ===========================================================
-- 1. get_fleet_capacity_dashboard
--    Returns a daily summary of fleet capacity & utilization
--    for a date range, aggregated across all technicians.
-- ===========================================================
CREATE OR REPLACE FUNCTION public.get_fleet_capacity_dashboard(
    p_start_date  DATE,
    p_days_ahead  INTEGER DEFAULT 14
)
RETURNS TABLE (
    target_date             DATE,
    total_capacity          INTEGER,
    total_booked            INTEGER,
    available_capacity      INTEGER,
    utilization_percentage  NUMERIC
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the fleet capacity dashboard.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(
            p_start_date,
            p_start_date + (p_days_ahead - 1)::INTEGER,
            INTERVAL '1 day'
        )::DATE AS day
    ),
    -- Aggregate effective capacity per technician per day
    -- Effective = override capacity if exists, else pool default
    tech_capacity AS (
        SELECT
            d.day,
            cp.technician_id,
            COALESCE(
                -- If blocked, capacity = 0
                CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
                cp.max_daily_capacity
            ) AS effective_capacity
        FROM date_series d
        CROSS JOIN public.capacity_pools cp
        LEFT JOIN public.capacity_overrides co
            ON co.pool_id = cp.id
           AND co.technician_id = cp.technician_id
           AND co.override_date = d.day
    ),
    -- Aggregate capacity per day across all technicians
    daily_capacity AS (
        SELECT
            day,
            SUM(effective_capacity) AS total_cap
        FROM tech_capacity
        GROUP BY day
    ),
    -- Count active bookings per day
    daily_bookings AS (
        SELECT
            scheduled_day::DATE AS day,
            COUNT(*) AS booked
        FROM public.bookings
        WHERE status NOT IN (
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician'
        )
          AND scheduled_day::DATE BETWEEN p_start_date AND p_start_date + (p_days_ahead - 1)::INTEGER
        GROUP BY scheduled_day::DATE
    )
    SELECT
        d.day                                                   AS target_date,
        COALESCE(dc.total_cap, 0)::INTEGER                     AS total_capacity,
        COALESCE(db.booked, 0)::INTEGER                        AS total_booked,
        GREATEST(0, COALESCE(dc.total_cap, 0) - COALESCE(db.booked, 0))::INTEGER AS available_capacity,
        CASE
            WHEN COALESCE(dc.total_cap, 0) = 0 THEN 0
            ELSE ROUND((COALESCE(db.booked, 0)::NUMERIC / dc.total_cap::NUMERIC) * 100, 1)
        END AS utilization_percentage
    FROM date_series d
    LEFT JOIN daily_capacity dc ON dc.day = d.day
    LEFT JOIN daily_bookings db ON db.day = d.day
    ORDER BY d.day;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_fleet_capacity_dashboard(DATE, INTEGER)
    TO authenticated;


-- ===========================================================
-- 2. get_technician_capacity_report
--    Returns per-technician breakdown for a specific day,
--    including workload, capacity and utilization status.
-- ===========================================================
CREATE OR REPLACE FUNCTION public.get_technician_capacity_report(
    p_target_date  DATE
)
RETURNS TABLE (
    technician_id           UUID,
    technician_name         TEXT,
    workload                INTEGER,
    capacity                INTEGER,
    utilization_percentage  NUMERIC,
    status                  TEXT
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the technician capacity report.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH tech_capacity AS (
        SELECT
            cp.technician_id,
            COALESCE(
                CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
                cp.max_daily_capacity
            ) AS effective_capacity,
            COALESCE(co.is_blocked, FALSE) AS is_blocked
        FROM public.capacity_pools cp
        LEFT JOIN public.capacity_overrides co
            ON co.pool_id = cp.id
           AND co.technician_id = cp.technician_id
           AND co.override_date = p_target_date
    ),
    agg_capacity AS (
        SELECT
            technician_id,
            SUM(effective_capacity)::INTEGER AS total_cap,
            BOOL_OR(is_blocked) AS is_blocked
        FROM tech_capacity
        GROUP BY technician_id
    ),
    daily_bookings AS (
        SELECT
            technician_id,
            COUNT(*)::INTEGER AS booked
        FROM public.bookings
        WHERE status NOT IN (
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician'
        )
          AND scheduled_day::DATE = p_target_date
          AND technician_id IS NOT NULL
        GROUP BY technician_id
    )
    SELECT
        ac.technician_id,
        p.first_name || ' ' || p.last_name                     AS technician_name,
        COALESCE(db.booked, 0)                                  AS workload,
        ac.total_cap                                            AS capacity,
        CASE
            WHEN ac.total_cap = 0 THEN 100
            ELSE ROUND((COALESCE(db.booked, 0)::NUMERIC / ac.total_cap::NUMERIC) * 100, 1)
        END                                                     AS utilization_percentage,
        CASE
            WHEN ac.is_blocked                              THEN 'blocked'
            WHEN ac.total_cap = 0                           THEN 'blocked'
            WHEN COALESCE(db.booked, 0) = 0                THEN 'idle'
            WHEN COALESCE(db.booked, 0) >= ac.total_cap    THEN 'full'
            WHEN COALESCE(db.booked, 0)::NUMERIC / ac.total_cap::NUMERIC >= 0.7 THEN 'healthy'
            ELSE 'idle'
        END                                                     AS status
    FROM agg_capacity ac
    JOIN public.profiles p ON p.id = ac.technician_id
    LEFT JOIN daily_bookings db ON db.technician_id = ac.technician_id
    ORDER BY utilization_percentage DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_technician_capacity_report(DATE)
    TO authenticated;


-- ===========================================================
-- 3. admin_reschedule_booking_atomic
--    Atomically moves a booking to a new date,
--    validating capacity on the destination day.
-- ===========================================================
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id  UUID,
    p_new_date    DATE
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
AS $$
DECLARE
    v_booking          public.bookings;
    v_tech_id          UUID;
    v_pool_id          UUID;
    v_cap              INTEGER;
    v_booked           INTEGER;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reschedule bookings.' USING ERRCODE = '42501';
    END IF;

    -- Fetch booking
    SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found: %', p_booking_id USING ERRCODE = 'P0001';
    END IF;

    v_tech_id := v_booking.technician_id;

    -- Verify technician is assigned
    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'Booking has no assigned technician.' USING ERRCODE = 'P0002';
    END IF;

    -- Get the technician's capacity pool for this service
    SELECT cp.id INTO v_pool_id
    FROM public.capacity_pools cp
    JOIN public.technician_skills ts
        ON ts.capacity_pool_id = cp.id AND ts.technician_id = cp.technician_id
    WHERE cp.technician_id = v_tech_id
      AND ts.sub_service_id = v_booking.service_id
    LIMIT 1;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'Technician capacity pool not found.' USING ERRCODE = 'P0003';
    END IF;

    -- Effective capacity for new date
    SELECT COALESCE(
        CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
        cp.max_daily_capacity
    ) INTO v_cap
    FROM public.capacity_pools cp
    LEFT JOIN public.capacity_overrides co
        ON co.pool_id = cp.id AND co.technician_id = cp.technician_id
       AND co.override_date = p_new_date
    WHERE cp.id = v_pool_id;

    -- Count existing bookings on new date for this technician
    SELECT COUNT(*)::INTEGER INTO v_booked
    FROM public.bookings
    WHERE technician_id = v_tech_id
      AND scheduled_day::DATE = p_new_date
      AND id != p_booking_id
      AND status NOT IN (
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician'
      );

    IF v_booked >= v_cap THEN
        RAISE EXCEPTION 'Technician is at full capacity on %. Cannot reschedule.', p_new_date
            USING ERRCODE = 'P0004';
    END IF;

    -- Perform the rescheduling
    UPDATE public.bookings
    SET scheduled_day = p_new_date
    WHERE id = p_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    -- Transition booking status via lifecycle gatekeeper
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        auth.uid(),
        'admin',
        'ADMIN_RESCHEDULE',
        'Admin rescheduled booking to ' || p_new_date::TEXT,
        jsonb_build_object('force_override', true)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_reschedule_booking_atomic(UUID, DATE)
    TO authenticated;


-- ===========================================================
-- 4. admin_reassign_booking
--    Reassigns a booking from its current technician to a 
--    new one, logging the change.
-- ===========================================================
CREATE OR REPLACE FUNCTION public.admin_reassign_booking(
    p_booking_id        UUID,
    p_new_technician_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
AS $$
DECLARE
    v_booking       public.bookings;
    v_old_tech_id   UUID;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reassign bookings.' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found: %', p_booking_id USING ERRCODE = 'P0001';
    END IF;

    -- Verify new technician exists
    IF NOT EXISTS (
        SELECT 1 FROM public.technician_profiles WHERE user_id = p_new_technician_id
    ) THEN
        RAISE EXCEPTION 'Target technician profile not found.' USING ERRCODE = 'P0002';
    END IF;

    v_old_tech_id := v_booking.technician_id;

    -- Perform reassignment
    UPDATE public.bookings
    SET technician_id = p_new_technician_id
    WHERE id = p_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    -- Transition booking status via lifecycle gatekeeper
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        auth.uid(),
        'admin',
        'ADMIN_REASSIGN',
        'Admin manually reassigned technician',
        jsonb_build_object('force_override', true)
    );

    -- Log into assignment_logs
    INSERT INTO public.assignment_logs (
        booking_id, new_technician_id, previous_technician_id, assigned_by, reason
    ) VALUES (
        p_booking_id,
        p_new_technician_id,
        v_old_tech_id,
        'admin',
        'Admin manual reassignment'
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_reassign_booking(UUID, UUID)
    TO authenticated;


-- ===========================================================
-- 5. admin_force_status_update
--    Allows admin to forcefully update a technician's 
--    effective capacity status on a specific date by writing
--    a capacity override (blocked / capacity value).
-- ===========================================================
CREATE OR REPLACE FUNCTION public.admin_force_status_update(
    p_technician_id  UUID,
    p_target_date    DATE,
    p_new_status     TEXT   -- 'blocked' | 'idle' | 'healthy' | 'full'
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
AS $$
DECLARE
    v_pool_id       UUID;
    v_max_cap       INTEGER;
    v_new_capacity  INTEGER;
    v_is_blocked    BOOLEAN;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can force capacity status updates.' USING ERRCODE = '42501';
    END IF;

    -- Get the first capacity pool for this technician
    SELECT id, max_daily_capacity INTO v_pool_id, v_max_cap
    FROM public.capacity_pools
    WHERE technician_id = p_technician_id
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'No capacity pool found for technician %', p_technician_id
            USING ERRCODE = 'P0001';
    END IF;

    -- Map status string to override values
    CASE p_new_status
        WHEN 'blocked' THEN
            v_is_blocked   := TRUE;
            v_new_capacity := NULL;
        WHEN 'idle' THEN
            v_is_blocked   := FALSE;
            v_new_capacity := v_max_cap; -- Reset to full availability
        WHEN 'full' THEN
            v_is_blocked   := FALSE;
            v_new_capacity := 0;         -- Zero remaining = full
        WHEN 'healthy' THEN
            v_is_blocked   := FALSE;
            v_new_capacity := GREATEST(1, (v_max_cap * 0.5)::INTEGER);
        ELSE
            RAISE EXCEPTION 'Invalid status: %. Valid: blocked, idle, healthy, full', p_new_status
                USING ERRCODE = 'P0002';
    END CASE;

    -- Upsert the override
    INSERT INTO public.capacity_overrides (
        pool_id, technician_id, override_date, new_capacity, is_blocked, reason
    ) VALUES (
        v_pool_id,
        p_technician_id,
        p_target_date,
        v_new_capacity,
        v_is_blocked,
        'Admin force status: ' || p_new_status
    )
    ON CONFLICT (technician_id, pool_id, override_date)
    DO UPDATE SET
        new_capacity = EXCLUDED.new_capacity,
        is_blocked   = EXCLUDED.is_blocked,
        reason       = EXCLUDED.reason,
        updated_at   = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_force_status_update(UUID, DATE, TEXT)
    TO authenticated;
