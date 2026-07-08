-- Migration ID: 90_fix_admin_reschedule_service_id_type
-- Description: Fix public.admin_reschedule_booking_atomic (4-parameter version) type mismatch where v_service_id was declared as UUID instead of TEXT. Also convert sub_service_id params from UUID to TEXT in capacity reports.

BEGIN;

-- 1. Drop old functions whose signatures are changing
DROP FUNCTION IF EXISTS public.get_fleet_capacity_report(DATE, DATE, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_technician_capacity_report(DATE, UUID) CASCADE;

-- 2. Redefine public.admin_reschedule_booking_atomic (4-parameter version)
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id   UUID,
    p_new_date     DATE,
    p_admin_id     UUID,
    p_reason       TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_tech_id      UUID;
    v_service_id   TEXT; -- Fixed: Was UUID, changed to TEXT to match bookings table schema
    v_pool_id      UUID;
    v_max_cap      INTEGER;
    v_current_load INTEGER;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reschedule bookings.' USING ERRCODE = '42501';
    END IF;

    -- 1. Get booking details
    SELECT technician_id, service_id INTO v_tech_id, v_service_id
    FROM public.bookings
    WHERE id = p_booking_id;

    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'Booking not found or not assigned' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Resolve Capacity Pool
    SELECT capacity_pool_id INTO v_pool_id
    FROM public.technician_skills
    WHERE technician_id  = v_tech_id
      AND sub_service_id = v_service_id
      AND is_active      = true;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'Technician does not have active skill for this service.' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Locking & Verification
    v_lock_key_1 := hashtext(v_tech_id::TEXT || v_pool_id::TEXT);
    v_lock_key_2 := hashtext(p_new_date::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    SELECT max_daily_capacity INTO v_max_cap FROM public.capacity_pools WHERE id = v_pool_id;
    
    SELECT COUNT(*) INTO v_current_load
    FROM public.bookings b
    WHERE b.technician_id = v_tech_id
      AND b.service_id    = v_service_id
      AND b.scheduled_day::DATE = p_new_date
      AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
      AND b.id != p_booking_id; -- Exclude self if already on this day

    IF v_current_load >= v_max_cap THEN
        RAISE EXCEPTION 'Capacity full for this technician on the new date.' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Update Booking & Log Event
    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        p_admin_id,
        'admin',
        'ADMIN_RESCHEDULE',
        COALESCE(p_reason, 'Order rescheduled to ' || p_new_date::TEXT)
    );

    UPDATE public.bookings 
    SET scheduled_day = p_new_date
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 3. Redefine public.get_fleet_capacity_report (p_sub_service_id as TEXT)
CREATE OR REPLACE FUNCTION public.get_fleet_capacity_report(
    p_start_date DATE,
    p_end_date   DATE,
    p_sub_service_id TEXT DEFAULT NULL
) RETURNS TABLE (
    sub_service_id         TEXT,
    sub_service_title      JSONB,
    target_date            DATE,
    active_technician_count BIGINT,
    total_capacity         BIGINT,
    total_bookings         BIGINT,
    available_slots        BIGINT,
    utilization            NUMERIC
) AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the fleet capacity report.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT d.day::DATE AS target_date
        FROM generate_series(p_start_date, p_end_date, '1 day'::INTERVAL) d(day)
    ),
    service_list AS (
        SELECT id, title
        FROM public.services
        WHERE is_bookable = true
          AND (p_sub_service_id IS NULL OR id = p_sub_service_id)
    ),
    tech_capabilities AS (
        -- Cross join technicians skilled for these services and check if blocked
        SELECT
            ds.target_date,
            sl.id AS sub_service_id,
            ts.technician_id,
            CASE
                WHEN co.is_blocked = TRUE THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_capacity
        FROM date_series ds
        CROSS JOIN service_list sl
        JOIN public.technician_skills ts ON ts.sub_service_id = sl.id
        JOIN public.capacity_pools cp    ON cp.id = ts.capacity_pool_id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = ts.capacity_pool_id
              AND co_inner.technician_id = ts.technician_id
              AND co_inner.override_date = ds.target_date
            ORDER BY co_inner.override_date DESC, co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE ts.is_active = true
    ),
    service_load AS (
        -- Count booked orders for these services across the date range
        SELECT
            (b.scheduled_day AT TIME ZONE 'UTC')::DATE AS target_date,
            b.service_id,
            COUNT(b.id) AS booked_count
        FROM public.bookings b
        WHERE b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
          AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE BETWEEN p_start_date AND p_end_date
        GROUP BY 1, 2
    )
    SELECT
        sl.id,
        sl.title,
        ds.target_date,
        COUNT(DISTINCT tc.technician_id) FILTER (WHERE tc.effective_capacity > 0),
        SUM(tc.effective_capacity)::BIGINT,
        COALESCE(l.booked_count, 0)::BIGINT,
        (SUM(tc.effective_capacity) - COALESCE(l.booked_count, 0))::BIGINT,
        ROUND(
            (COALESCE(l.booked_count, 0)::DECIMAL / NULLIF(SUM(tc.effective_capacity), 0)) * 100, 
            2
        )
    FROM date_series ds
    CROSS JOIN service_list sl
    LEFT JOIN tech_capabilities tc ON tc.target_date = ds.target_date AND tc.sub_service_id = sl.id
    LEFT JOIN service_load l      ON l.target_date = ds.target_date AND l.service_id = sl.id
    GROUP BY sl.id, sl.title, ds.target_date
    ORDER BY ds.target_date, sl.title->>'en';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 4. Redefine public.get_technician_capacity_report (p_sub_service_id as TEXT)
CREATE OR REPLACE FUNCTION public.get_technician_capacity_report(
    p_date DATE,
    p_sub_service_id TEXT DEFAULT NULL
) RETURNS TABLE (
    technician_id    UUID,
    first_name       TEXT,
    last_name        TEXT,
    pool_title       TEXT,
    effective_cap    INTEGER,
    current_load     BIGINT,
    is_blocked       BOOLEAN,
    status           TEXT
) AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the technician capacity report.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH tech_stats AS (
        SELECT
            tp.user_id,
            pr.first_name,
            pr.last_name,
            cp.title AS pool_title,
            cp.id AS pool_id,
            CASE
                WHEN co.is_blocked = TRUE THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_capacity,
            COALESCE(co.is_blocked, false) AS blocked_flag,
            (
                SELECT COUNT(*)
                FROM public.bookings b
                JOIN public.technician_skills s ON s.sub_service_id = b.service_id
                WHERE s.capacity_pool_id = cp.id
                  AND b.scheduled_day::DATE = p_date
                  AND (b.technician_id = tp.user_id OR b.technician_id IS NULL)
                  AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
            ) AS load_count
        FROM public.technician_profiles tp
        JOIN public.profiles pr ON pr.id = tp.user_id
        JOIN public.capacity_pools cp ON cp.technician_id = tp.user_id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = cp.id
              AND co_inner.technician_id = tp.user_id
              AND co_inner.override_date = p_date
            ORDER BY co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE (p_sub_service_id IS NULL OR EXISTS (
            SELECT 1 FROM public.technician_skills ts 
            WHERE ts.technician_id = tp.user_id AND ts.sub_service_id = p_sub_service_id
        ))
    )
    SELECT
        t.user_id,
        t.first_name,
        t.last_name,
        t.pool_title,
        t.effective_capacity,
        t.load_count::BIGINT,
        t.blocked_flag,
        CASE
            WHEN t.blocked_flag THEN 'blocked'
            WHEN t.load_count > t.effective_capacity THEN 'overloaded'
            WHEN t.load_count = t.effective_capacity THEN 'full'
            ELSE 'healthy'
        END::TEXT
    FROM tech_stats t;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;
