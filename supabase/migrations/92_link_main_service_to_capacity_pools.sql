-- Migration ID: 92_link_main_service_to_capacity_pools
-- Description: Link main services directly to capacity pools instead of technician profiles. Correct capacity calculations to check full pool load.

BEGIN;

-- 1. Truncate old data to prevent foreign key issues and mismatch during development
TRUNCATE TABLE public.technician_skills CASCADE;
TRUNCATE TABLE public.capacity_pools CASCADE;

-- 2. Add main_service_id column to capacity_pools table
ALTER TABLE public.capacity_pools 
ADD COLUMN main_service_id TEXT NOT NULL REFERENCES public.services(id) ON DELETE CASCADE;

-- 3. Add constraint trigger to verify capacity_pools main_service_id points to a root category service (parent_id IS NULL)
CREATE OR REPLACE FUNCTION public.fn_verify_capacity_pool_main_service()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.services 
        WHERE id = NEW.main_service_id 
          AND parent_id IS NULL 
          AND is_bookable = false
        LIMIT 1
    ) THEN
        RAISE EXCEPTION 'Capacity pool must be linked to a root-level main service category.' USING ERRCODE = 'P0009';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verify_capacity_pool_main_service ON public.capacity_pools;
CREATE TRIGGER trg_verify_capacity_pool_main_service
BEFORE INSERT OR UPDATE ON public.capacity_pools
FOR EACH ROW EXECUTE FUNCTION public.fn_verify_capacity_pool_main_service();

-- 4. Add constraint trigger to verify technician_skills belongs to the pool's main_service
CREATE OR REPLACE FUNCTION public.fn_verify_technician_skill_pool_service()
RETURNS TRIGGER AS $$
DECLARE
    v_pool_main_service_id TEXT;
    v_sub_service_parent_id TEXT;
BEGIN
    -- Get the main_service_id of the capacity pool
    SELECT main_service_id INTO v_pool_main_service_id
    FROM public.capacity_pools
    WHERE id = NEW.capacity_pool_id;

    -- Get the parent_id (main service) of the sub-service
    SELECT parent_id INTO v_sub_service_parent_id
    FROM public.services
    WHERE id = NEW.sub_service_id;

    IF v_pool_main_service_id IS NOT NULL AND v_sub_service_parent_id IS NOT NULL AND v_pool_main_service_id != v_sub_service_parent_id THEN
        RAISE EXCEPTION 'Sub-service does not belong to the main service of the selected capacity pool.' USING ERRCODE = 'P0008';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_verify_technician_skill_pool_service ON public.technician_skills;
CREATE TRIGGER trg_verify_technician_skill_pool_service
BEFORE INSERT OR UPDATE ON public.technician_skills
FOR EACH ROW EXECUTE FUNCTION public.fn_verify_technician_skill_pool_service();

-- 5. Redefine public.get_available_technicians to correctly calculate total pool load
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
            cp.max_daily_capacity
        FROM public.technician_skills ts
        JOIN public.capacity_pools cp ON ts.capacity_pool_id = cp.id
        WHERE ts.sub_service_id = p_sub_service_id
          AND ts.is_active = true
    ),
    pool_load AS (
        SELECT
            pm.technician_id,
            pm.capacity_pool_id,
            COUNT(b.id) FILTER (WHERE b.technician_id = pm.technician_id) AS assigned_load,
            COUNT(b.id) FILTER (WHERE b.technician_id IS NULL) AS unassigned_load
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
    )
    SELECT
        tp.user_id,
        pr.first_name,
        pr.last_name,
        pr.avatar_url,
        tp.rating,
        (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::BIGINT,
        pm.max_daily_capacity
    FROM pool_mapping pm
    JOIN public.technician_profiles tp ON tp.user_id = pm.technician_id
    JOIN public.profiles pr ON pr.id = tp.user_id
    JOIN pool_load pl ON pl.technician_id = pm.technician_id
                     AND pl.capacity_pool_id = pm.capacity_pool_id
    WHERE tp.is_available = true
      AND pr.account_status = 'active'
      AND (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0)) < pm.max_daily_capacity
    ORDER BY tp.rating DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 6. Redefine public.admin_reschedule_booking_atomic to correctly calculate total pool load
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id   UUID,
    p_new_date     DATE,
    p_admin_id     UUID,
    p_reason       TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_tech_id      UUID;
    v_service_id   TEXT;
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
    JOIN public.technician_skills s ON s.sub_service_id = b.service_id
    WHERE b.technician_id = v_tech_id
      AND s.capacity_pool_id = v_pool_id
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

-- 7. Redefine public.admin_reassign_booking to correctly calculate total pool load
CREATE OR REPLACE FUNCTION public.admin_reassign_booking(
    p_booking_id       UUID,
    p_new_technician_id UUID,
    p_admin_id         UUID,
    p_reason           TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_service_id   TEXT;
    v_pool_id      UUID;
    v_max_cap      INTEGER;
    v_current_load INTEGER;
    v_scheduled_day DATE;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reassign bookings.' USING ERRCODE = '42501';
    END IF;

    -- 1. Get booking details
    SELECT service_id, scheduled_day::DATE INTO v_service_id, v_scheduled_day
    FROM public.bookings
    WHERE id = p_booking_id;

    -- 2. Resolve Capacity Pool for NEW technician
    SELECT capacity_pool_id INTO v_pool_id
    FROM public.technician_skills
    WHERE technician_id  = p_new_technician_id
      AND sub_service_id = v_service_id
      AND is_active      = true;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'New technician does not have active skill for this service.' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Locking & Verification
    v_lock_key_1 := hashtext(p_new_technician_id::TEXT || v_pool_id::TEXT);
    v_lock_key_2 := hashtext(v_scheduled_day::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    SELECT max_daily_capacity INTO v_max_cap FROM public.capacity_pools WHERE id = v_pool_id;
    
    SELECT COUNT(*) INTO v_current_load
    FROM public.bookings b
    JOIN public.technician_skills s ON s.sub_service_id = b.service_id
    WHERE b.technician_id   = p_new_technician_id
      AND s.capacity_pool_id = v_pool_id
      AND b.scheduled_day::DATE = v_scheduled_day
      AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2);

    IF v_current_load >= v_max_cap THEN
        RAISE EXCEPTION 'Target technician is at full capacity for this day.' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Update Booking & Log Event
    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        p_admin_id,
        'admin',
        'ADMIN_REASSIGN',
        COALESCE(p_reason, 'Technician reassigned by admin')
    );

    UPDATE public.bookings 
    SET technician_id = p_new_technician_id
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMIT;
