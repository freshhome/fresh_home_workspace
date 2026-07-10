-- Migration ID: 93_fix_admin_reschedule_reassign_force_override
-- Description: Restore force_override behavior in admin_reschedule_booking_atomic and admin_reassign_booking to allow overrides from accepted/ready statuses.

BEGIN;

-- 1. Redefine public.admin_reschedule_booking_atomic to pass force_override: true
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
        COALESCE(p_reason, 'Order rescheduled to ' || p_new_date::TEXT),
        jsonb_build_object('force_override', true) -- Fixed: Force override status checks
    );

    UPDATE public.bookings 
    SET scheduled_day = p_new_date
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 2. Redefine public.admin_reassign_booking to pass force_override: true
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
        COALESCE(p_reason, 'Technician reassigned by admin'),
        jsonb_build_object('force_override', true) -- Fixed: Force override status checks
    );

    UPDATE public.bookings 
    SET technician_id = p_new_technician_id
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMIT;
