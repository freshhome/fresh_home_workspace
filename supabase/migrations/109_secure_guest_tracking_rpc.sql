-- ==============================================================================
-- Migration: 109_secure_guest_tracking_rpc.sql
-- Description: Phase 4 (Step 4.1 & 4.2) - Secure Guest Tracking RPC & Readable ID Support
--              1. Modifies public.get_guest_booking_details to accept p_booking_id TEXT
--                 supporting both UUID and Readable ID (e.g. 'FH-100293' or '100293').
--              2. Protects customer PII (addresses, phone numbers) from exposure via
--                 raw UUID: masks sensitive data unless caller is admin or provides
--                 matching contact phone (p_phone).
--              3. Hides technician details if booking is unconfirmed (is_whatsapp_confirmed = false).
-- Spec Reference: docs_guest/guest_booking_rules.md & guest_booking_development_plan.md
-- ==============================================================================

BEGIN;

-- Drop previous UUID-only signature to avoid overloading ambiguity
DROP FUNCTION IF EXISTS public.get_guest_booking_details(UUID);

CREATE OR REPLACE FUNCTION public.get_guest_booking_details(
    p_booking_id TEXT,
    p_phone      TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking         RECORD;
    v_tech_name       TEXT := NULL;
    v_tech_rating     NUMERIC(3,2) := 5.0;
    v_tech_jobs       INTEGER := 0;
    v_price_config    JSONB := NULL;
    v_is_uuid         BOOLEAN := FALSE;
    v_phone_verified  BOOLEAN := FALSE;
    v_input_digits    TEXT := '';
    v_safe_address    JSONB;
    v_safe_phones     TEXT[];
BEGIN
    IF p_booking_id IS NULL OR TRIM(p_booking_id) = '' THEN
        RETURN NULL;
    END IF;

    -- 1. Determine if input is a valid UUID or a readable identifier
    v_is_uuid := (p_booking_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

    IF v_is_uuid THEN
        SELECT b.* INTO v_booking
        FROM public.bookings b
        WHERE b.id = p_booking_id::UUID;
    ELSE
        SELECT b.* INTO v_booking
        FROM public.bookings b
        WHERE b.readable_id ILIKE TRIM(p_booking_id)
           OR b.readable_id ILIKE ('FH-' || TRIM(p_booking_id));
    END IF;

    IF NOT FOUND OR v_booking.id IS NULL THEN
        RETURN NULL;
    END IF;

    -- 2. Privacy & Verification Logic: Admin or matching phone
    IF public.is_admin() THEN
        v_phone_verified := TRUE;
    ELSIF p_phone IS NOT NULL AND TRIM(p_phone) != '' THEN
        v_input_digits := regexp_replace(p_phone, '\D', '', 'g');
        IF v_input_digits != '' AND (
            EXISTS (
                SELECT 1 FROM unnest(v_booking.contact_phones) ph
                WHERE regexp_replace(ph, '\D', '', 'g') = v_input_digits
                   OR (length(v_input_digits) >= 10 AND regexp_replace(ph, '\D', '', 'g') LIKE ('%' || v_input_digits))
                   OR (length(regexp_replace(ph, '\D', '', 'g')) >= 10 AND v_input_digits LIKE ('%' || regexp_replace(ph, '\D', '', 'g')))
            ) OR (
                v_booking.pricing_inputs ->> 'phone' IS NOT NULL
                AND regexp_replace(v_booking.pricing_inputs ->> 'phone', '\D', '', 'g') = v_input_digits
            )
        ) THEN
            v_phone_verified := TRUE;
        END IF;
    END IF;

    -- 3. Mask PII for unverified callers while preserving status and tracking data
    IF v_phone_verified THEN
        v_safe_address := v_booking.address_snapshot;
        v_safe_phones  := v_booking.contact_phones;
    ELSE
        -- Keep only governorate, city, district for public status tracking
        v_safe_address := jsonb_build_object(
            'governorate', COALESCE(v_booking.address_snapshot->>'governorate', v_booking.address_snapshot->'address'->>'governorate', 'القاهرة'),
            'city', COALESCE(v_booking.address_snapshot->>'city', v_booking.address_snapshot->'address'->>'city', ''),
            'district', COALESCE(v_booking.address_snapshot->>'district', v_booking.address_snapshot->'address'->>'district', '')
        );

        -- Mask phone numbers (e.g. 010****5678)
        IF v_booking.contact_phones IS NOT NULL AND array_length(v_booking.contact_phones, 1) > 0 THEN
            v_safe_phones := ARRAY[
                CASE 
                    WHEN length(v_booking.contact_phones[1]) >= 7 THEN 
                        substr(v_booking.contact_phones[1], 1, 3) || '****' || substr(v_booking.contact_phones[1], length(v_booking.contact_phones[1]) - 3)
                    ELSE '****'
                END
            ];
        ELSE
            v_safe_phones := '{}'::TEXT[];
        END IF;
    END IF;

    -- 4. Load price configuration of the sub-service
    SELECT s.price_config INTO v_price_config
    FROM public.services s
    WHERE s.id = v_booking.service_id;

    -- 5. Fetch technician details only if assigned and WhatsApp confirmed
    IF v_booking.technician_id IS NOT NULL AND v_booking.is_whatsapp_confirmed THEN
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
        'created_at', v_booking.created_at,
        'scheduled_day', v_booking.scheduled_day,
        'start_time_slot', v_booking.start_time_slot,
        'address_snapshot', v_safe_address,
        'service_snapshot', v_booking.service_snapshot,
        'price_snapshot', v_booking.price_snapshot,
        'pricing_inputs', v_booking.pricing_inputs,
        'price_config', v_price_config,
        'contact_name', CASE WHEN v_phone_verified THEN v_booking.contact_name ELSE 'العميل' END,
        'contact_phones', v_safe_phones,
        'is_whatsapp_confirmed', v_booking.is_whatsapp_confirmed,
        'technician_id', CASE WHEN v_booking.is_whatsapp_confirmed THEN v_booking.technician_id ELSE NULL END,
        'technician', CASE 
            WHEN v_booking.technician_id IS NOT NULL AND v_booking.is_whatsapp_confirmed THEN 
                jsonb_build_object(
                    'name', COALESCE(v_tech_name, 'فني معتمد'),
                    'rating', COALESCE(v_tech_rating, 5.0),
                    'completed_jobs', COALESCE(v_tech_jobs, 0)
                )
            ELSE NULL 
        END,
        'is_phone_verified', v_phone_verified
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_guest_booking_details(TEXT, TEXT) TO anon, authenticated, service_role;

COMMIT;
