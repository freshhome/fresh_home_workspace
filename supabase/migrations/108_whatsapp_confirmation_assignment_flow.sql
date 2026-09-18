-- ==============================================================================
-- Migration: 108_whatsapp_confirmation_assignment_flow.sql
-- Description: Phase 3 (Step 3.1 & 3.2) - Dynamic Technician Assignment upon WhatsApp Confirmation
--              1. Re-defines confirm_whatsapp_booking to dynamically allocate an available
--                 technician upon customer confirmation, transition from 'created' to 'assigned',
--                 and handle capacity exhaustion without faking technicians.
--              2. Re-defines admin_confirm_whatsapp_booking to allow admins to confirm and
--                 assign an available or specified technician, transitioning to 'assigned'.
-- Spec Reference: docs_guest/guest_booking_rules.md & guest_booking_development_plan.md
-- ==============================================================================

BEGIN;

-- 1. RE-DEFINE public.confirm_whatsapp_booking WITH DYNAMIC ASSIGNMENT
CREATE OR REPLACE FUNCTION public.confirm_whatsapp_booking(
    p_booking_id UUID,
    p_token      UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_booking    public.bookings;
    v_tech_id    UUID := NULL;
    v_lock_key_1 INT;
    v_lock_key_2 INT;
BEGIN
    -- 1. Fetch booking with update lock
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id AND whatsapp_confirmation_token = p_token
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'رابط التأكيد غير صالح أو منتهي الصلاحية.' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Check if already confirmed (Idempotent)
    IF v_booking.is_whatsapp_confirmed AND v_booking.status != 'created'::public.order_status_v2 THEN
        RETURN TRUE;
    END IF;

    -- 3. Check expiration
    IF v_booking.whatsapp_confirmation_expires_at IS NOT NULL AND v_booking.whatsapp_confirmation_expires_at < NOW() THEN
        RAISE EXCEPTION 'عذراً، انتهت صلاحية مهلة تأكيد الحجز (60 دقيقة). يرجى بدء حجز جديد.' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Dynamic Technician Allocation if not already assigned
    IF v_booking.technician_id IS NULL THEN
        -- Search for an available technician for this service and scheduled day
        SELECT technician_id INTO v_tech_id
        FROM public.get_available_technicians(v_booking.service_id, (v_booking.scheduled_day)::DATE)
        LIMIT 1;

        IF v_tech_id IS NOT NULL THEN
            -- Acquire advisory transaction lock for technician and date
            v_lock_key_1 := hashtext(v_tech_id::TEXT);
            v_lock_key_2 := hashtext(v_booking.scheduled_day::TEXT);
            PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

            -- Update booking with confirmed status and assigned technician
            UPDATE public.bookings
            SET 
                technician_id = v_tech_id,
                is_whatsapp_confirmed = true,
                whatsapp_confirmation_expires_at = NULL,
                updated_at = NOW()
            WHERE id = p_booking_id;

            -- Set trusted session flag to allow internal state transition
            PERFORM set_config('app.trusted_internal_call', 'true', true);

            -- Transition status from 'created' to 'assigned'
            PERFORM public.transition_booking(
                p_booking_id,
                'assigned'::public.order_status_v2,
                NULL::UUID,
                'customer',
                'WHATSAPP_CONFIRMED',
                'تم تأكيد الحجز عبر واتساب وتخصيص الفني المتاح بنجاح.'
            );

            -- Log event in booking_events
            INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
            VALUES (
                p_booking_id,
                'WHATSAPP_CONFIRMED',
                NULL,
                'customer',
                jsonb_build_object(
                    'method', 'whatsapp_link',
                    'technician_id', v_tech_id,
                    'status', 'assigned'
                )
            );
        ELSE
            -- Capacity Exhaustion: Do NOT fake technician or exceed capacity.
            -- Mark confirmed but leave technician_id NULL for Admin intervention.
            UPDATE public.bookings
            SET 
                is_whatsapp_confirmed = true,
                whatsapp_confirmation_expires_at = NULL,
                updated_at = NOW()
            WHERE id = p_booking_id;

            INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
            VALUES (
                p_booking_id,
                'WHATSAPP_CONFIRMED',
                NULL,
                'customer',
                jsonb_build_object(
                    'method', 'whatsapp_link',
                    'capacity_exhausted', true,
                    'needs_admin_intervention', true
                )
            );
        END IF;

    ELSE
        -- Technician was already pre-assigned (e.g. legacy or special flow)
        UPDATE public.bookings
        SET 
            is_whatsapp_confirmed = true,
            whatsapp_confirmation_expires_at = NULL,
            updated_at = NOW()
        WHERE id = p_booking_id;

        IF v_booking.status = 'created'::public.order_status_v2 THEN
            PERFORM set_config('app.trusted_internal_call', 'true', true);
            PERFORM public.transition_booking(
                p_booking_id,
                'assigned'::public.order_status_v2,
                NULL::UUID,
                'customer',
                'WHATSAPP_CONFIRMED',
                'تم تأكيد الحجز وتنشيط الإسناد للفني.'
            );
        END IF;

        INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
        VALUES (
            p_booking_id,
            'WHATSAPP_CONFIRMED',
            NULL,
            'customer',
            jsonb_build_object(
                'method', 'whatsapp_link',
                'technician_id', v_booking.technician_id,
                'status', 'assigned'
            )
        );
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.confirm_whatsapp_booking(UUID, UUID) TO anon, authenticated, service_role;


-- 2. RE-DEFINE public.admin_confirm_whatsapp_booking WITH MANUAL / DYNAMIC ASSIGNMENT
CREATE OR REPLACE FUNCTION public.admin_confirm_whatsapp_booking(
    p_booking_id    UUID,
    p_technician_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_booking    public.bookings;
    v_tech_id    UUID := NULL;
    v_lock_key_1 INT;
    v_lock_key_2 INT;
BEGIN
    -- 1. Verify actor is an admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can manually confirm bookings.' USING ERRCODE = '42501';
    END IF;

    -- 2. Fetch booking with update lock
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الحجز غير موجود.' USING ERRCODE = 'P0002';
    END IF;

    -- 3. Determine Technician
    IF v_booking.technician_id IS NULL THEN
        IF p_technician_id IS NOT NULL THEN
            v_tech_id := p_technician_id;
        ELSE
            -- Auto-resolve available technician if not explicitly provided
            SELECT technician_id INTO v_tech_id
            FROM public.get_available_technicians(v_booking.service_id, (v_booking.scheduled_day)::DATE)
            LIMIT 1;
        END IF;

        IF v_tech_id IS NOT NULL THEN
            v_lock_key_1 := hashtext(v_tech_id::TEXT);
            v_lock_key_2 := hashtext(v_booking.scheduled_day::TEXT);
            PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

            UPDATE public.bookings
            SET 
                technician_id = v_tech_id,
                is_whatsapp_confirmed = true,
                whatsapp_confirmation_expires_at = NULL,
                updated_at = NOW()
            WHERE id = p_booking_id;

            PERFORM set_config('app.trusted_internal_call', 'true', true);

            PERFORM public.transition_booking(
                p_booking_id,
                'assigned'::public.order_status_v2,
                auth.uid(),
                'admin',
                'WHATSAPP_CONFIRMED',
                'تم تأكيد الحجز يدوياً من الإدارة وتخصيص الفني.'
            );
        ELSE
            -- No technician available; still update confirmation and clear expiry
            UPDATE public.bookings
            SET 
                is_whatsapp_confirmed = true,
                whatsapp_confirmation_expires_at = NULL,
                updated_at = NOW()
            WHERE id = p_booking_id;
        END IF;
    ELSE
        -- Technician already assigned
        v_tech_id := v_booking.technician_id;
        UPDATE public.bookings
        SET 
            is_whatsapp_confirmed = true,
            whatsapp_confirmation_expires_at = NULL,
            updated_at = NOW()
        WHERE id = p_booking_id;

        IF v_booking.status = 'created'::public.order_status_v2 THEN
            PERFORM set_config('app.trusted_internal_call', 'true', true);
            PERFORM public.transition_booking(
                p_booking_id,
                'assigned'::public.order_status_v2,
                auth.uid(),
                'admin',
                'WHATSAPP_CONFIRMED',
                'تم تأكيد الحجز يدوياً من الإدارة وتنشيط الإسناد للفني.'
            );
        END IF;
    END IF;

    -- Log event
    INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
    VALUES (
        p_booking_id,
        'WHATSAPP_CONFIRMED',
        auth.uid(),
        'admin',
        jsonb_build_object(
            'method', 'admin_manual',
            'technician_id', v_tech_id,
            'status', 'assigned'
        )
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_confirm_whatsapp_booking(UUID, UUID) TO authenticated, service_role;

-- Overload helper: allow callers passing TIMESTAMPTZ directly without explicit cast
CREATE OR REPLACE FUNCTION public.get_available_technicians(
    p_sub_service_id TEXT,
    p_date           TIMESTAMPTZ
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
    RETURN QUERY SELECT * FROM public.get_available_technicians(p_sub_service_id, (p_date AT TIME ZONE 'UTC')::DATE);
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION public.get_available_technicians(TEXT, TIMESTAMPTZ) TO anon, authenticated, service_role;

COMMIT;
