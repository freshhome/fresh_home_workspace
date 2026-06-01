-- ==============================================================================
-- Fresh Home: Audited Booking Updates (v1.0)
-- File: 22_audited_booking_updates.sql
--
-- Objective: Provide secure, audited RPCs for updating booking details 
--            without bypassing the State Machine or Audit Trail.
-- ==============================================================================

-- 1. RPC: Update Booking Schedule (Audited)
CREATE OR REPLACE FUNCTION public.customer_update_booking_schedule(
    p_booking_id    UUID,
    p_new_day       DATE,
    p_new_time_slot TIME,
    p_actor_id      UUID
) RETURNS VOID AS $$
DECLARE
    v_old_day       DATE;
    v_old_time      TIME;
    v_status        public.order_status_v2;
    v_tech_id       UUID;
    v_service_id    UUID;
    v_booking_user_id UUID;
    v_is_available  BOOLEAN;
BEGIN
    -- A. Fetch current state and lock
    SELECT scheduled_day, start_time_slot, status, technician_id, service_id, user_id 
    INTO v_old_day, v_old_time, v_status, v_tech_id, v_service_id, v_booking_user_id
    FROM public.bookings WHERE id = p_booking_id FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'الحجز غير موجود'; END IF;

    -- B. Enforce Authentication & Authorization
    IF auth.uid() IS NOT NULL THEN
        p_actor_id := auth.uid();
        IF NOT (public.is_admin() OR v_booking_user_id = auth.uid()) THEN
            RAISE EXCEPTION 'Unauthorized: Access to update this booking is restricted.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- C. Business Validation: Status Check
    -- Scheduling only allowed in early stages
    IF v_status NOT IN ('created', 'assigned', 'accepted', 'ready', 'pending') THEN
        RAISE EXCEPTION 'لا يمكن تعديل الموعد بعد بدء التنفيذ أو إلغاء الحجز';
    END IF;

    -- D. Availability/Capacity Check
    -- Reuse existing availability logic
    SELECT EXISTS (
        SELECT 1 FROM public.get_available_technicians(v_service_id, p_new_day)
        WHERE technician_id = v_tech_id
    ) INTO v_is_available;

    IF NOT v_is_available THEN
        RAISE EXCEPTION 'الفني غير متاح في الموعد الجديد أو تم بلوغ الحد الأقصى للسعة';
    END IF;

    -- E. Atomic Update
    UPDATE public.bookings
    SET scheduled_day = p_new_day,
        start_time_slot = p_new_time_slot,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- F. Detailed Audit Trail
    INSERT INTO public.booking_events (
        booking_id, event_type, actor_id, actor_role, metadata
    ) VALUES (
        p_booking_id,
        'SCHEDULE_UPDATE',
        p_actor_id,
        CASE WHEN p_actor_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.user_roles ur JOIN public.roles r ON ur.role_id = r.id 
            WHERE ur.user_id = p_actor_id AND r.name = 'admin'
        ) THEN 'admin' ELSE 'customer' END,
        jsonb_build_object(
            'old_schedule', jsonb_build_object('day', v_old_day, 'time', v_old_time),
            'new_schedule', jsonb_build_object('day', p_new_day, 'time', p_new_time_slot)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. RPC: Update Booking Address & Contact (Audited)
CREATE OR REPLACE FUNCTION public.customer_update_booking_address(
    p_booking_id       UUID,
    p_address_snapshot JSONB,
    p_contact_snapshot JSONB,
    p_actor_id         UUID
) RETURNS VOID AS $$
DECLARE
    v_old_address JSONB;
    v_old_contact JSONB;
    v_status      public.order_status_v2;
    v_booking_user_id UUID;
BEGIN
    -- A. Fetch current state and lock
    SELECT address_snapshot, service_snapshot->'contact', status, user_id
    INTO v_old_address, v_old_contact, v_status, v_booking_user_id
    FROM public.bookings WHERE id = p_booking_id FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'الحجز غير موجود'; END IF;

    -- B. Enforce Authentication & Authorization
    IF auth.uid() IS NOT NULL THEN
        p_actor_id := auth.uid();
        IF NOT (public.is_admin() OR v_booking_user_id = auth.uid()) THEN
            RAISE EXCEPTION 'Unauthorized: Access to update this booking is restricted.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- C. Business Validation
    IF v_status NOT IN ('created', 'assigned', 'accepted', 'ready', 'pending') THEN
        RAISE EXCEPTION 'لا يمكن تعديل العنوان بعد وصول الفني أو بدء العمل';
    END IF;

    -- D. Atomic Update
    UPDATE public.bookings
    SET address_snapshot = p_address_snapshot,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- E. Detailed Audit Trail
    INSERT INTO public.booking_events (
        booking_id, event_type, actor_id, actor_role, metadata
    ) VALUES (
        p_booking_id,
        'ADDRESS_UPDATE',
        p_actor_id,
        CASE WHEN p_actor_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.user_roles ur JOIN public.roles r ON ur.role_id = r.id 
            WHERE ur.user_id = p_actor_id AND r.name = 'admin'
        ) THEN 'admin' ELSE 'customer' END,
        jsonb_build_object(
            'old_address', v_old_address,
            'new_address', p_address_snapshot
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.customer_update_booking_schedule IS 'Updates booking day/time with capacity check and audit trail.';
COMMENT ON FUNCTION public.customer_update_booking_address IS 'Updates booking address snapshot with status check and audit trail.';
