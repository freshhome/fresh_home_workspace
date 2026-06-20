-- Migration ID: 77_make_booking_user_id_nullable
-- Description: Drop NOT NULL constraint on bookings.user_id to allow guest checkouts, fix create_atomic_booking to use TEXT sub_service_id, and add get_guest_booking_details RPC.

BEGIN;

-- 1. Drop the NOT NULL constraint on user_id in the bookings table
ALTER TABLE public.bookings ALTER COLUMN user_id DROP NOT NULL;

-- 2. Drop the old UUID-based create_atomic_booking signature to avoid conflicts
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT, BOOLEAN) CASCADE;

-- 3. Re-create create_atomic_booking with p_sub_service_id as TEXT (matching services table type)
CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id                UUID,
    p_sub_service_id         TEXT, -- TEXT instead of UUID
    p_technician_id          UUID,
    p_scheduled_day          DATE,
    p_address_snapshot       JSONB,
    p_service_snapshot       JSONB,
    p_pricing_inputs         JSONB,
    p_contact_name           TEXT DEFAULT 'Client',
    p_contact_phones         TEXT[] DEFAULT '{}'::TEXT[],
    p_start_time_slot        TIME DEFAULT '09:00',
    p_actor_id               UUID DEFAULT NULL,
    p_actor_role             TEXT DEFAULT 'admin',
    p_is_whatsapp_confirmed  BOOLEAN DEFAULT true
) RETURNS UUID AS $$
DECLARE
    v_tech_id        UUID;
    v_booking_id     UUID;
    v_lock_key_1     INT;
    v_lock_key_2     INT;
    v_pipeline_res   JSONB;
    v_price_snapshot JSONB;
    v_price_config   JSONB;
    v_version_id     UUID;
    v_is_bookable    BOOLEAN;
    v_expiry_minutes INT;
BEGIN
    -- Verify booking creation authorization (Standard user must only book for themselves)
    IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
        IF p_user_id != auth.uid() THEN
            RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- Resolve technician (Auto-assign if not specified)
    IF p_technician_id IS NULL THEN
        SELECT technician_id INTO v_tech_id
        FROM public.get_available_technicians(p_sub_service_id, p_scheduled_day)
        LIMIT 1;

        IF v_tech_id IS NULL THEN
            RAISE EXCEPTION 'لا يوجد فني متاح لهذا اليوم' USING ERRCODE = 'P0002';
        END IF;
    ELSE
        v_tech_id := p_technician_id;
    END IF;

    v_lock_key_1 := hashtext(v_tech_id::TEXT);
    v_lock_key_2 := hashtext(p_scheduled_day::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    -- Load price configuration and verify it is bookable
    SELECT price_config, is_bookable INTO v_price_config, v_is_bookable
    FROM public.services
    WHERE id = p_sub_service_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الخدمة المحددة غير موجودة' USING ERRCODE = 'P0002';
    END IF;

    IF NOT v_is_bookable THEN
        RAISE EXCEPTION 'لا يمكن حجز فئة أو قسم غير قابل للحجز' USING ERRCODE = 'P0009';
    END IF;

    -- Calculate price authoritatively via deterministic execution contract pipeline
    v_pipeline_res := public.execute_pricing_pipeline(p_sub_service_id, v_price_config, p_pricing_inputs);

    -- Extract version_id and formatted totals snapshot
    v_version_id := (v_pipeline_res -> 'metadata' ->> 'pricing_version_id')::UUID;
    v_price_snapshot := jsonb_build_object(
        'basePrice', (v_pipeline_res ->> 'basePrice')::NUMERIC,
        'extraFees', (v_pipeline_res ->> 'extraFees')::NUMERIC,
        'discount', (v_pipeline_res ->> 'discount')::NUMERIC,
        'total', (v_pipeline_res ->> 'total')::NUMERIC,
        'metadata', v_pipeline_res -> 'metadata'
    );

    -- Load confirmation expiry settings
    SELECT COALESCE((value->>'expiry_minutes')::integer, 60) INTO v_expiry_minutes
    FROM public.system_settings
    WHERE key = 'whatsapp_settings';

    INSERT INTO public.bookings (
        user_id, technician_id, service_id, scheduled_day, start_time_slot,
        address_snapshot, service_snapshot, price_snapshot,
        pricing_inputs, pricing_version_id,
        contact_name, contact_phones,
        status,
        is_whatsapp_confirmed,
        whatsapp_confirmation_expires_at,
        whatsapp_confirmation_token
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, v_price_snapshot,
        COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2,
        p_is_whatsapp_confirmed,
        CASE WHEN NOT p_is_whatsapp_confirmed THEN NOW() + (v_expiry_minutes || ' minutes')::interval ELSE NULL END,
        gen_random_uuid()
    ) RETURNING id INTO v_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    -- Transition to assigned state via official state machine
    PERFORM public.transition_booking(
        v_booking_id,
        'assigned'::public.order_status_v2,
        COALESCE(p_actor_id, p_user_id),
        p_actor_role,
        'BOOKING_CREATION',
        'تم إنشاء الحجز وتخصيص الفني، في انتظار التأكيد عبر واتساب.'
    );

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 4. Create get_guest_booking_details SECURITY DEFINER function to allow guests to retrieve booking details safely
CREATE OR REPLACE FUNCTION public.get_guest_booking_details(p_booking_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking RECORD;
    v_tech_name TEXT := NULL;
    v_tech_rating NUMERIC(3,2) := 5.0;
    v_tech_jobs INTEGER := 0;
BEGIN
    SELECT b.* INTO v_booking
    FROM public.bookings b
    WHERE b.id = p_booking_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Fetch technician details if assigned
    IF v_booking.technician_id IS NOT NULL THEN
        SELECT p.first_name || ' ' || p.last_name, tp.rating, tp.completed_jobs
        INTO v_tech_name, v_tech_rating, v_tech_jobs
        FROM public.profiles p
        LEFT JOIN public.technician_profiles tp ON tp.user_id = p.id
        WHERE p.id = v_booking.technician_id;
    END IF;

    RETURN jsonb_build_object(
        'id', v_booking.id,
        'readable_id', v_booking.readable_id,
        'status', v_booking.status,
        'scheduled_day', v_booking.scheduled_day,
        'start_time_slot', v_booking.start_time_slot,
        'address_snapshot', v_booking.address_snapshot,
        'service_snapshot', v_booking.service_snapshot,
        'price_snapshot', v_booking.price_snapshot,
        'contact_name', v_booking.contact_name,
        'contact_phones', v_booking.contact_phones,
        'is_whatsapp_confirmed', v_booking.is_whatsapp_confirmed,
        'technician_id', v_booking.technician_id,
        'technician', CASE 
            WHEN v_booking.technician_id IS NOT NULL THEN 
                jsonb_build_object(
                    'name', COALESCE(v_tech_name, 'فني معتمد'),
                    'rating', COALESCE(v_tech_rating, 5.0),
                    'completed_jobs', COALESCE(v_tech_jobs, 0)
                )
            ELSE NULL 
        END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_guest_booking_details(UUID) TO anon, authenticated;

COMMIT;
