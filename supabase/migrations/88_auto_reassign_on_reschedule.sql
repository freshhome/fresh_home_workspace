-- Migration ID: 88_auto_reassign_on_reschedule
-- Description: Enhance customer_update_booking_schedule to support automatic technician reassignment when rescheduling, with transactional advisory locking to prevent double booking. Fixes UUID/TEXT type cast issue on v_service_id.

BEGIN;

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
    v_service_id    TEXT; -- Fixed type from UUID to TEXT to match the bookings table schema
    v_booking_user_id UUID;
    v_is_available  BOOLEAN;
    v_new_tech_id   UUID;
    v_old_tech_id   UUID;
    v_reassigned    BOOLEAN := FALSE;
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
    IF v_status NOT IN ('created', 'assigned', 'accepted', 'ready', 'pending') THEN
        RAISE EXCEPTION 'لا يمكن تعديل الموعد بعد بدء التنفيذ أو إلغاء الحجز';
    END IF;

    -- D. Availability/Capacity Check & Automatic Reassignment (with Concurrency Protection)
    v_is_available := FALSE;
    
    IF v_tech_id IS NOT NULL THEN
        -- Acquire transactional advisory lock for current technician + new day
        PERFORM pg_advisory_xact_lock(hashtext(v_tech_id::TEXT), hashtext(p_new_day::TEXT));
        
        -- Check if current technician is available on the new date
        SELECT EXISTS (
            SELECT 1 FROM public.get_available_technicians(v_service_id::TEXT, p_new_day)
            WHERE technician_id = v_tech_id
        ) INTO v_is_available;
    END IF;

    IF NOT v_is_available THEN
        -- Loop through available candidates, lock and verify to prevent double booking
        FOR v_new_tech_id IN 
            SELECT technician_id FROM public.get_available_technicians(v_service_id::TEXT, p_new_day)
            ORDER BY rating DESC, current_load ASC
        LOOP
            -- Lock candidate + date
            PERFORM pg_advisory_xact_lock(hashtext(v_new_tech_id::TEXT), hashtext(p_new_day::TEXT));
            
            -- Re-verify availability under lock
            SELECT EXISTS (
                SELECT 1 FROM public.get_available_technicians(v_service_id::TEXT, p_new_day)
                WHERE technician_id = v_new_tech_id
            ) INTO v_is_available;
            
            IF v_is_available THEN
                v_old_tech_id := v_tech_id;
                v_tech_id := v_new_tech_id;
                v_reassigned := TRUE;
                EXIT; -- Valid technician locked and found
            END IF;
        END LOOP;

        IF NOT v_is_available THEN
            RAISE EXCEPTION 'لا يوجد فني متاح في هذا التاريخ أو تم بلغ الحد الأقصى للسعة' USING ERRCODE = 'P0002';
        END IF;
    END IF;

    -- E. Atomic Update
    UPDATE public.bookings
    SET scheduled_day = p_new_day,
        start_time_slot = p_new_time_slot,
        technician_id = v_tech_id,
        status = CASE WHEN v_reassigned THEN 'assigned'::public.order_status_v2 ELSE status END,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- F. Detailed Audit Trail
    -- Event 1: Schedule Update
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

    -- Event 2: Technician Reassigned (if changed)
    IF v_reassigned THEN
        INSERT INTO public.booking_events (
            booking_id, event_type, actor_id, actor_role, metadata
        ) VALUES (
            p_booking_id,
            'TECHNICIAN_REASSIGNED',
            p_actor_id,
            CASE WHEN p_actor_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.user_roles ur JOIN public.roles r ON ur.role_id = r.id 
                WHERE ur.user_id = p_actor_id AND r.name = 'admin'
            ) THEN 'admin' ELSE 'customer' END,
            jsonb_build_object(
                'old_technician_id', v_old_tech_id,
                'new_technician_id', v_tech_id,
                'reason', 'System automatically reassigned technician due to schedule update'
            )
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
