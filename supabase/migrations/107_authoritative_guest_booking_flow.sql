-- ==============================================================================
-- Migration: 107_authoritative_guest_booking_flow.sql
-- Description: Phase 2 (Step 2.1 & 2.2) - Authoritative Backend Guest Booking Logic
--              1. Re-defines create_atomic_booking to enforce Backend Authority.
--              2. For Guests (p_user_id IS NULL or auth.uid() IS NULL):
--                 - Ignores client-supplied p_is_whatsapp_confirmed parameter.
--                 - Runs duplicate detection for same scheduled_day + same service.
--                 - Evaluates correlation signals (normalized phone, browser_id).
--                 - Fork A (First booking / No duplicate / Different day / Different service):
--                   Allocates technician, reserves capacity, is_whatsapp_confirmed = true,
--                   transitions to 'assigned'.
--                 - Fork B (Duplicate same-day, same-service):
--                   technician_id = NULL, zero capacity reserved, is_whatsapp_confirmed = false,
--                   remains in 'created' status, 60-minute expiry set.
-- Spec Reference: docs_guest/guest_booking_rules.md & guest_booking_development_plan.md
-- ==============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id                UUID,
    p_sub_service_id         TEXT,
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
    v_tech_id             UUID := NULL;
    v_booking_id          UUID;
    v_lock_key_1          INT;
    v_lock_key_2          INT;
    v_pipeline_res        JSONB;
    v_price_snapshot      JSONB;
    v_price_config        JSONB;
    v_version_id          UUID;
    v_is_bookable         BOOLEAN;
    v_expiry_minutes      INT;
    v_governorate         TEXT;
    v_gov_id              INT;
    
    -- Backend Authority & Guest Signals variables
    v_is_guest            BOOLEAN;
    v_requires_whatsapp   BOOLEAN := false;
    v_input_raw_phone     TEXT := '';
    v_input_digits        TEXT := '';
    v_input_norm_phone    TEXT := '';
    v_input_browser_id    TEXT := NULL;
    v_has_duplicate       BOOLEAN := false;
BEGIN
    -- 1. Verify booking creation authorization (Standard user must only book for themselves)
    IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
        IF p_user_id != auth.uid() THEN
            RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- 2. Determine Guest Status
    v_is_guest := (auth.uid() IS NULL AND p_user_id IS NULL);

    -- 3. Enforce Geographic Coverage Guard (Cairo & Giza Only)
    v_governorate := TRIM(COALESCE(
        p_address_snapshot -> 'address' ->> 'governorate_ar',
        p_address_snapshot -> 'address' ->> 'governorate',
        p_address_snapshot ->> 'governorate_ar',
        p_address_snapshot ->> 'governorate',
        ''
    ));

    IF v_governorate = '' THEN
        BEGIN
            v_gov_id := COALESCE(
                (p_address_snapshot -> 'address' ->> 'governorate_id')::INT,
                (p_address_snapshot ->> 'governorate_id')::INT,
                NULL
            );
            IF v_gov_id = 1 THEN
                v_governorate := 'القاهرة';
            ELSIF v_gov_id = 2 THEN
                v_governorate := 'الجيزة';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_governorate := '';
        END;
    END IF;

    IF LOWER(v_governorate) IN ('cairo', 'el cairo', 'al qahirah', 'cairo governorate') THEN
        v_governorate := 'القاهرة';
    ELSIF LOWER(v_governorate) IN ('giza', 'el giza', 'al gizah', 'giza governorate') THEN
        v_governorate := 'الجيزة';
    END IF;

    IF v_governorate NOT IN ('القاهرة', 'الجيزة') THEN
        RAISE EXCEPTION 'عذراً، خدمات فريش هوم متاحة حالياً داخل محافظتي القاهرة والجيزة فقط.' USING ERRCODE = 'P0020';
    END IF;

    -- 4. Load price configuration and verify it is bookable
    SELECT price_config, is_bookable INTO v_price_config, v_is_bookable
    FROM public.services
    WHERE id = p_sub_service_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الخدمة المحددة غير موجودة' USING ERRCODE = 'P0002';
    END IF;

    IF NOT v_is_bookable THEN
        RAISE EXCEPTION 'لا يمكن حجز فئة أو قسم غير قابل للحجز' USING ERRCODE = 'P0009';
    END IF;

    -- 5. Calculate price authoritatively via deterministic execution contract pipeline
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

    -- 6. Load confirmation expiry settings (Default 60 minutes)
    SELECT COALESCE((value->>'expiry_minutes')::integer, 60) INTO v_expiry_minutes
    FROM public.system_settings
    WHERE key = 'whatsapp_settings';

    -- 7. Backend Authority: Evaluate Duplicate Detection for Guest
    IF v_is_guest THEN
        -- Normalize phone signals
        v_input_raw_phone := COALESCE(
            CASE WHEN array_length(p_contact_phones, 1) > 0 THEN p_contact_phones[1] ELSE NULL END,
            p_pricing_inputs ->> 'phone',
            ''
        );
        v_input_digits := regexp_replace(v_input_raw_phone, '\D', '', 'g');
        
        IF v_input_digits LIKE '01%' AND length(v_input_digits) = 11 THEN
            v_input_norm_phone := '2' || v_input_digits;
        ELSIF v_input_digits LIKE '002%' THEN
            v_input_norm_phone := substr(v_input_digits, 3);
        ELSE
            v_input_norm_phone := v_input_digits;
        END IF;

        -- Extract optional browser_id signal from client context
        v_input_browser_id := NULLIF(TRIM(COALESCE(
            p_pricing_inputs ->> 'browser_id',
            p_pricing_inputs ->> 'client_id',
            ''
        )), '');

        -- Check for existing active booking for the SAME DAY and SAME SERVICE
        SELECT EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.user_id IS NULL
              AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE = (p_scheduled_day AT TIME ZONE 'UTC')::DATE
              AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
              AND (
                  b.service_id = p_sub_service_id
                  OR b.service_id IN (
                      SELECT s.id FROM public.services s
                      WHERE s.parent_id IS NOT NULL 
                        AND s.parent_id = (SELECT s2.parent_id FROM public.services s2 WHERE s2.id = p_sub_service_id)
                  )
              )
              AND (
                  -- Signal A: Phone match (normalized)
                  (
                      v_input_norm_phone != '' 
                      AND (
                          EXISTS (
                              SELECT 1 FROM unnest(b.contact_phones) ph
                              WHERE regexp_replace(ph, '\D', '', 'g') = v_input_digits
                                 OR (length(regexp_replace(ph, '\D', '', 'g')) = 11 AND '2' || regexp_replace(ph, '\D', '', 'g') = v_input_norm_phone)
                                 OR (length(regexp_replace(ph, '\D', '', 'g')) = 12 AND regexp_replace(ph, '\D', '', 'g') = v_input_norm_phone)
                          )
                          OR (
                              b.pricing_inputs ->> 'phone' IS NOT NULL 
                              AND (
                                  regexp_replace(b.pricing_inputs ->> 'phone', '\D', '', 'g') = v_input_digits
                                  OR (length(regexp_replace(b.pricing_inputs ->> 'phone', '\D', '', 'g')) = 11 AND '2' || regexp_replace(b.pricing_inputs ->> 'phone', '\D', '', 'g') = v_input_norm_phone)
                                  OR (length(regexp_replace(b.pricing_inputs ->> 'phone', '\D', '', 'g')) = 12 AND regexp_replace(b.pricing_inputs ->> 'phone', '\D', '', 'g') = v_input_norm_phone)
                              )
                          )
                      )
                  )
                  -- Signal B: Browser ID match
                  OR (
                      v_input_browser_id IS NOT NULL
                      AND (
                          b.pricing_inputs ->> 'browser_id' = v_input_browser_id
                          OR b.pricing_inputs ->> 'client_id' = v_input_browser_id
                      )
                  )
              )
        ) INTO v_has_duplicate;

        IF v_has_duplicate THEN
            v_requires_whatsapp := true;
        ELSE
            v_requires_whatsapp := false;
        END IF;
    ELSE
        -- Authenticated customer bookings do not require WhatsApp confirmation
        v_requires_whatsapp := false;
    END IF;


    -- 8. FORK EXECUTION PATHS
    IF NOT v_requires_whatsapp THEN
        -- ── FORK A: Normal Confirmed Booking Flow ─────────────────────────────
        -- Resolve technician
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

        -- Concurrency lock on assigned technician and date
        v_lock_key_1 := hashtext(v_tech_id::TEXT);
        v_lock_key_2 := hashtext(p_scheduled_day::TEXT);
        PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

        -- Insert confirmed booking
        INSERT INTO public.bookings (
            user_id, technician_id, service_id, scheduled_day, start_time_slot,
            address_snapshot, service_snapshot, price_snapshot,
            pricing_inputs, pricing_version_id,
            contact_name, contact_phones,
            status,
            is_whatsapp_confirmed,
            whatsapp_confirmation_expires_at,
            whatsapp_confirmation_token,
            payment_method
        ) VALUES (
            p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
            p_address_snapshot, p_service_snapshot, v_price_snapshot,
            COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
            p_contact_name, p_contact_phones,
            'created'::public.order_status_v2,
            true,
            NULL,
            gen_random_uuid(),
            COALESCE(p_pricing_inputs ->> 'payment_method', 'cash')
        ) RETURNING id INTO v_booking_id;

        -- Set session flag and transition to assigned
        PERFORM set_config('app.trusted_internal_call', 'true', true);
        PERFORM public.transition_booking(
            v_booking_id,
            'assigned'::public.order_status_v2,
            COALESCE(p_actor_id, p_user_id),
            p_actor_role,
            'BOOKING_CREATION',
            'تم إنشاء الحجز وتخصيص الفني بنجاح.'
        );

    ELSE
        -- ── FORK B: Duplicate Guest WhatsApp Pending Flow ─────────────────────
        -- No technician allocation, No advisory lock, Zero capacity consumption
        v_tech_id := NULL;

        -- Insert unconfirmed booking in 'created' state
        INSERT INTO public.bookings (
            user_id, technician_id, service_id, scheduled_day, start_time_slot,
            address_snapshot, service_snapshot, price_snapshot,
            pricing_inputs, pricing_version_id,
            contact_name, contact_phones,
            status,
            is_whatsapp_confirmed,
            whatsapp_confirmation_expires_at,
            whatsapp_confirmation_token,
            payment_method
        ) VALUES (
            NULL, NULL, p_sub_service_id, p_scheduled_day, p_start_time_slot,
            p_address_snapshot, p_service_snapshot, v_price_snapshot,
            COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
            p_contact_name, p_contact_phones,
            'created'::public.order_status_v2,
            false,
            NOW() + (v_expiry_minutes || ' minutes')::interval,
            gen_random_uuid(),
            COALESCE(p_pricing_inputs ->> 'payment_method', 'cash')
        ) RETURNING id INTO v_booking_id;

        -- Record event in audit log (Do NOT transition to 'assigned')
        INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
        VALUES (
            v_booking_id,
            'BOOKING_CREATION',
            NULL,
            'customer',
            jsonb_build_object(
                'requires_whatsapp_confirmation', true,
                'reason', 'duplicate_same_day_same_service'
            )
        );

    END IF;

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_atomic_booking(
    UUID, TEXT, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT, BOOLEAN
) TO anon, authenticated, service_role;

COMMIT;
