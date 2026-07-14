-- Migration ID: 95_reschedule_logic_capacity_overrides
-- Description: Update public.get_available_technicians to respect capacity_overrides (day-off and custom capacity), and redefine public.admin_reschedule_booking_atomic to prioritize the current technician but fall back to the next available technician if unavailable.

BEGIN;

-- 1. Redefine public.get_available_technicians
CREATE OR REPLACE FUNCTION public.get_available_technicians(
    p_sub_service_id TEXT,
    p_date           DATE
) RETURNS TABLE (
    technician_id   UUID,
    first_name      TEXT,
    last_name       TEXT,
    avatar_url      TEXT,
    rating          DECIMAL,
    current_load    BIGINT,
    max_capacity    INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH pool_mapping AS (
        SELECT
            ts.technician_id,
            ts.capacity_pool_id,
            COALESCE(
                CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
                cp.max_daily_capacity
            )::INTEGER AS max_daily_capacity
        FROM public.technician_skills ts
        JOIN public.capacity_pools cp ON ts.capacity_pool_id = cp.id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = ts.capacity_pool_id
              AND co_inner.technician_id = ts.technician_id
              AND co_inner.override_date = p_date
            ORDER BY co_inner.override_date DESC, co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE ts.sub_service_id = p_sub_service_id
          AND ts.is_active = true
    ),
    pool_load AS (
        SELECT
            pm.technician_id,
            pm.capacity_pool_id,
            COUNT(b.id) FILTER (WHERE b.technician_id = pm.technician_id) AS assigned_load,
            COUNT(b.id) FILTER (WHERE b.technician_id IS NULL) AS unassigned_load,
            MAX(b.assigned_at) FILTER (WHERE b.technician_id = pm.technician_id) AS last_assigned_at
        FROM pool_mapping pm
        LEFT JOIN public.bookings b 
               ON (b.technician_id = pm.technician_id OR b.technician_id IS NULL)
              AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE = p_date
              AND b.service_id IN (
                  SELECT ts_inner.sub_service_id
                  FROM public.technician_skills ts_inner
                  WHERE ts_inner.capacity_pool_id = pm.capacity_pool_id
              )
              AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
        GROUP BY pm.technician_id, pm.capacity_pool_id
    ),
    candidates AS (
        SELECT
            tp.user_id,
            pr.first_name,
            pr.last_name,
            pr.avatar_url,
            tp.rating,
            (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::BIGINT as load,
            pm.max_daily_capacity,
            CASE 
                WHEN pm.max_daily_capacity = 0 THEN 1.0 
                ELSE ((COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::float / pm.max_daily_capacity)
            END as current_utilization,
            pl.last_assigned_at
        FROM pool_mapping pm
        JOIN public.technician_profiles tp ON tp.user_id = pm.technician_id
        JOIN public.profiles pr ON pr.id = tp.user_id
        JOIN pool_load pl ON pl.technician_id = pm.technician_id
                         AND pl.capacity_pool_id = pm.capacity_pool_id
        WHERE tp.is_available = true
          AND pr.account_status = 'active'
          AND (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0)) < pm.max_daily_capacity
    ),
    utilization_check AS (
        SELECT EXISTS (
            SELECT 1 FROM candidates WHERE current_utilization < 0.5
        ) as has_anyone_under_fifty
    )
    SELECT
        c.user_id,
        c.first_name,
        c.last_name,
        c.avatar_url,
        c.rating,
        c.load,
        c.max_daily_capacity
    FROM candidates c
    CROSS JOIN utilization_check uc
    WHERE 
      -- Apply ExcludeExceedingFiftyPercentRule (منع تجاوز 50% قبل الجميع)
      (NOT uc.has_anyone_under_fifty OR c.current_utilization < 0.5)
    ORDER BY 
      -- Rule 1: Proportional Share Interleaving (prospective utilization ascending)
      ((c.load + 1)::float / NULLIF(c.max_daily_capacity, 0)) ASC,
      -- Tie-breaker: Larger capacity first
      c.max_daily_capacity DESC,
      -- Rule 2: Rating Ranking (higher rating first)
      c.rating DESC,
      -- Rule 3: FIFO / Longest Idle Time (last_assigned_at ascending)
      c.last_assigned_at ASC NULLS FIRST,
      -- Final Tie Breaker: Random
      random();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. Redefine public.admin_reschedule_booking_atomic (4-parameter version)
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id   UUID,
    p_new_date     DATE,
    p_admin_id     UUID,
    p_reason       TEXT DEFAULT NULL,
    p_new_time     TIME DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_tech_id      UUID;
    v_new_tech_id  UUID;
    v_service_id   TEXT;
    v_is_available BOOLEAN;
    v_reassigned   BOOLEAN := FALSE;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reschedule bookings.' USING ERRCODE = '42501';
    END IF;

    -- A. Get booking details
    SELECT technician_id, service_id INTO v_tech_id, v_service_id
    FROM public.bookings
    WHERE id = p_booking_id;

    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'Booking not found or not assigned' USING ERRCODE = 'P0002';
    END IF;

    -- B. Check if current technician is available on the new date
    SELECT EXISTS (
        SELECT 1 FROM public.get_available_technicians(v_service_id, p_new_date)
        WHERE technician_id = v_tech_id
    ) INTO v_is_available;

    IF v_is_available THEN
        v_new_tech_id := v_tech_id;
    ELSE
        -- C. Find the best available alternative technician
        SELECT technician_id INTO v_new_tech_id
        FROM public.get_available_technicians(v_service_id, p_new_date)
        LIMIT 1;

        IF v_new_tech_id IS NULL THEN
            RAISE EXCEPTION 'اليوم المطلوب لإعادة الجدولة غير متاح (لا يوجد فنيين متاحين)' USING ERRCODE = 'P0004';
        END IF;

        v_reassigned := TRUE;
    END IF;

    -- D. Locking to prevent race conditions
    v_lock_key_1 := hashtext(v_new_tech_id::TEXT);
    v_lock_key_2 := hashtext(p_new_date::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    -- Re-verify availability under lock
    SELECT EXISTS (
        SELECT 1 FROM public.get_available_technicians(v_service_id, p_new_date)
        WHERE technician_id = v_new_tech_id
    ) INTO v_is_available;

    IF NOT v_is_available THEN
        RAISE EXCEPTION 'اليوم المطلوب لإعادة الجدولة غير متاح (لا يوجد فنيين متاحين)' USING ERRCODE = 'P0004';
    END IF;

    -- E. Update Booking & Log Event
    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        p_admin_id,
        'admin',
        'ADMIN_RESCHEDULE',
        COALESCE(p_reason, 'Order rescheduled to ' || p_new_date::TEXT || CASE WHEN v_reassigned THEN ' and reassigned to new technician.' ELSE '' END),
        jsonb_build_object('force_override', true)
    );

    UPDATE public.bookings 
    SET scheduled_day = p_new_date,
        start_time_slot = COALESCE(p_new_time, start_time_slot),
        technician_id = v_new_tech_id,
        status = 'assigned'::public.order_status_v2
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 3. Redefine public.admin_reschedule_booking_atomic (2-parameter version)
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id  UUID,
    p_new_date    DATE,
    p_new_time    TIME DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_tech_id      UUID;
    v_new_tech_id  UUID;
    v_service_id   TEXT;
    v_is_available BOOLEAN;
    v_reassigned   BOOLEAN := FALSE;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reschedule bookings.' USING ERRCODE = '42501';
    END IF;

    -- A. Get booking details
    SELECT technician_id, service_id INTO v_tech_id, v_service_id
    FROM public.bookings
    WHERE id = p_booking_id;

    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'Booking not found or not assigned' USING ERRCODE = 'P0002';
    END IF;

    -- B. Check if current technician is available on the new date
    SELECT EXISTS (
        SELECT 1 FROM public.get_available_technicians(v_service_id, p_new_date)
        WHERE technician_id = v_tech_id
    ) INTO v_is_available;

    IF v_is_available THEN
        v_new_tech_id := v_tech_id;
    ELSE
        -- C. Find the best available alternative technician
        SELECT technician_id INTO v_new_tech_id
        FROM public.get_available_technicians(v_service_id, p_new_date)
        LIMIT 1;

        IF v_new_tech_id IS NULL THEN
            RAISE EXCEPTION 'اليوم المطلوب لإعادة الجدولة غير متاح (لا يوجد فنيين متاحين)' USING ERRCODE = 'P0004';
        END IF;

        v_reassigned := TRUE;
    END IF;

    -- D. Locking to prevent race conditions
    v_lock_key_1 := hashtext(v_new_tech_id::TEXT);
    v_lock_key_2 := hashtext(p_new_date::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    -- Re-verify availability under lock
    SELECT EXISTS (
        SELECT 1 FROM public.get_available_technicians(v_service_id, p_new_date)
        WHERE technician_id = v_new_tech_id
    ) INTO v_is_available;

    IF NOT v_is_available THEN
        RAISE EXCEPTION 'اليوم المطلوب لإعادة الجدولة غير متاح (لا يوجد فنيين متاحين)' USING ERRCODE = 'P0004';
    END IF;

    -- E. Update Booking & Log Event
    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        auth.uid(),
        'admin',
        'ADMIN_RESCHEDULE',
        'Admin rescheduled booking to ' || p_new_date::TEXT || CASE WHEN v_reassigned THEN ' and reassigned to new technician.' ELSE '' END,
        jsonb_build_object('force_override', true)
    );

    UPDATE public.bookings 
    SET scheduled_day = p_new_date,
        start_time_slot = COALESCE(p_new_time, start_time_slot),
        technician_id = v_new_tech_id,
        status = 'assigned'::public.order_status_v2
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMIT;
