-- ==============================================================================
-- Script: verify_guest_booking_system.sql
-- Description: End-to-End Automated Verification Script for Guest Booking System
--              Executes all 7 test scenarios defined in guest_booking_development_plan.md
--              and guest_booking_rules.md.
--
-- How to run: Execute directly in Supabase SQL Editor.
-- The script runs safely, outputs detailed results for each scenario, and rolls back
-- test mutations cleanly to prevent cluttering production data.
-- ==============================================================================

BEGIN;

CREATE TEMP TABLE IF NOT EXISTS test_results (
    test_id     INT,
    test_name   TEXT,
    status      TEXT,
    details     TEXT
);

TRUNCATE TABLE test_results;

DO $$
DECLARE
    v_service_id         TEXT;
    v_diff_service_id    TEXT;
    v_test_phone         TEXT := '01099887766';
    v_test_browser_id    TEXT := 'test-browser-signal-xyz-999';
    v_test_day           DATE := CURRENT_DATE + INTERVAL '5 days';
    v_test_diff_day      DATE := CURRENT_DATE + INTERVAL '6 days';
    
    v_booking_1_id       UUID;
    v_booking_2_id       UUID;
    v_booking_3_id       UUID;
    v_booking_4_id       UUID;
    v_booking_5_id       UUID;
    
    v_b1_confirmed       BOOLEAN;
    v_b1_status          TEXT;
    v_b1_tech            UUID;
    
    v_b2_confirmed       BOOLEAN;
    v_b2_status          TEXT;
    v_b2_tech            UUID;
    
    v_b3_confirmed       BOOLEAN;
    v_b3_status          TEXT;
    
    v_b4_confirmed       BOOLEAN;
    v_b4_status          TEXT;
    
    v_b5_confirmed       BOOLEAN;
    v_b5_status          TEXT;
    
    v_b2_token           UUID;
    v_b2_after_status    TEXT;
    v_b2_after_confirmed BOOLEAN;
    v_b2_after_tech      UUID;
    
    v_guest_details      JSONB;
    v_readable_id        TEXT;
    v_pricing_payload    JSONB;
BEGIN
    v_pricing_payload := jsonb_build_object(
        'phone', v_test_phone, 
        'browser_id', v_test_browser_id, 
        'area', 50, 
        'rooms', 2, 
        'unit_count', 1, 
        'selected_options', '[]'::jsonb
    );
    -- 0. Find valid bookable services that have available technicians
    SELECT s.id INTO v_service_id
    FROM public.services s
    WHERE s.is_bookable = true 
      AND s.status = 'active'
      AND EXISTS (
          SELECT 1 FROM public.get_available_technicians(s.id, v_test_day::DATE)
      )
    LIMIT 1;

    -- Find second bookable service from a DIFFERENT category that has available technicians
    SELECT s.id INTO v_diff_service_id
    FROM public.services s
    WHERE s.is_bookable = true 
      AND s.status = 'active' 
      AND s.id != v_service_id
      AND s.parent_id IS DISTINCT FROM (SELECT parent_id FROM public.services WHERE id = v_service_id)
      AND EXISTS (
          SELECT 1 FROM public.get_available_technicians(s.id, v_test_day::DATE)
      )
    LIMIT 1;

    -- If no different category has available technicians, dynamically create test pool and skill inside transaction
    IF v_diff_service_id IS NULL THEN
        SELECT s.id INTO v_diff_service_id
        FROM public.services s
        WHERE s.is_bookable = true 
          AND s.status = 'active' 
          AND s.parent_id IS NOT NULL
          AND s.parent_id != (SELECT parent_id FROM public.services WHERE id = v_service_id)
        LIMIT 1;

        IF v_diff_service_id IS NOT NULL THEN
            DECLARE
                v_p_id   TEXT;
                v_c_pool UUID;
                v_t_id   UUID;
            BEGIN
                SELECT parent_id INTO v_p_id FROM public.services WHERE id = v_diff_service_id;
                SELECT technician_id INTO v_t_id FROM public.technician_skills WHERE sub_service_id = v_service_id LIMIT 1;
                
                IF v_t_id IS NOT NULL AND v_p_id IS NOT NULL THEN
                    SELECT id INTO v_c_pool FROM public.capacity_pools WHERE main_service_id = v_p_id LIMIT 1;
                    IF v_c_pool IS NULL THEN
                        INSERT INTO public.capacity_pools (name, main_service_id, max_daily_capacity)
                        VALUES ('Test Pool Different Category', v_p_id, 20)
                        RETURNING id INTO v_c_pool;
                    END IF;
                    
                    INSERT INTO public.technician_skills (technician_id, sub_service_id, capacity_pool_id, is_active)
                    VALUES (v_t_id, v_diff_service_id, v_c_pool, true)
                    ON CONFLICT DO NOTHING;
                END IF;
            END;
        END IF;
    END IF;

    IF v_service_id IS NULL THEN
        RAISE EXCEPTION 'No active bookable services with available technicians found to run verification!';
    END IF;

    -- ==========================================================================
    -- TEST 1: First Guest Booking (Must be confirmed immediately Fork A)
    -- ==========================================================================
    BEGIN
        v_booking_1_id := public.create_atomic_booking(
            p_user_id               := NULL,
            p_sub_service_id        := v_service_id,
            p_technician_id         := NULL,
            p_scheduled_day         := v_test_day,
            p_address_snapshot      := '{"governorate": "القاهرة", "city": "مدينة نصر", "district": "المنطقة الأولى", "street": "شارع النزهة"}'::JSONB,
            p_service_snapshot      := '{"title": "خدمة تجريبية"}'::JSONB,
            p_pricing_inputs        := v_pricing_payload,
            p_contact_name          := 'العميل التجريبي الأول',
            p_contact_phones        := ARRAY[v_test_phone],
            p_start_time_slot       := '10:00',
            p_is_whatsapp_confirmed := false -- Client passes false, Backend authority should override to true for 1st booking!
        );

        SELECT is_whatsapp_confirmed, status, technician_id, readable_id
        INTO v_b1_confirmed, v_b1_status, v_b1_tech, v_readable_id
        FROM public.bookings
        WHERE id = v_booking_1_id;

        IF v_b1_confirmed = true AND v_b1_status = 'assigned' THEN
            INSERT INTO test_results VALUES (1, 'Test 1: First Guest Booking', 'PASSED', 
                format('Booking confirmed immediately: is_whatsapp_confirmed=true, status=%s, tech_assigned=%s', v_b1_status, (v_b1_tech IS NOT NULL)::text));
        ELSE
            INSERT INTO test_results VALUES (1, 'Test 1: First Guest Booking', 'FAILED', 
                format('Expected is_whatsapp_confirmed=true & status=assigned, but got confirmed=%s, status=%s', v_b1_confirmed, v_b1_status));
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (1, 'Test 1: First Guest Booking', 'ERROR', SQLERRM);
    END;

    -- ==========================================================================
    -- TEST 2: Duplicate Same-Day, Same-Service (Must require WhatsApp Fork B)
    -- ==========================================================================
    BEGIN
        v_booking_2_id := public.create_atomic_booking(
            p_user_id               := NULL,
            p_sub_service_id        := v_service_id, -- Same service
            p_technician_id         := NULL,
            p_scheduled_day         := v_test_day,   -- Same day
            p_address_snapshot      := '{"governorate": "القاهرة", "city": "مدينة نصر", "district": "المنطقة الأولى"}'::JSONB,
            p_service_snapshot      := '{"title": "خدمة تجريبية ثانية"}'::JSONB,
            p_pricing_inputs        := v_pricing_payload,
            p_contact_name          := 'العميل التجريبي - حجز مكرر',
            p_contact_phones        := ARRAY[v_test_phone],
            p_start_time_slot       := '14:00'
        );

        SELECT is_whatsapp_confirmed, status, technician_id, whatsapp_confirmation_token
        INTO v_b2_confirmed, v_b2_status, v_b2_tech, v_b2_token
        FROM public.bookings
        WHERE id = v_booking_2_id;

        IF v_b2_confirmed = false AND v_b2_status = 'created' AND v_b2_tech IS NULL THEN
            INSERT INTO test_results VALUES (2, 'Test 2: Duplicate Same-Day Same-Service', 'PASSED', 
                'Correctly identified duplicate: status=created, is_whatsapp_confirmed=false, technician_id=NULL (Zero capacity consumed)');
        ELSE
            INSERT INTO test_results VALUES (2, 'Test 2: Duplicate Same-Day Same-Service', 'FAILED', 
                format('Expected status=created & confirmed=false & tech=NULL, got confirmed=%s, status=%s, tech=%s', v_b2_confirmed, v_b2_status, v_b2_tech));
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (2, 'Test 2: Duplicate Same-Day Same-Service', 'ERROR', SQLERRM);
    END;

    -- ==========================================================================
    -- TEST 3: Different Day, Same Service (Must be normal confirmed booking)
    -- ==========================================================================
    BEGIN
        v_booking_3_id := public.create_atomic_booking(
            p_user_id               := NULL,
            p_sub_service_id        := v_service_id,    -- Same service
            p_technician_id         := NULL,
            p_scheduled_day         := v_test_diff_day, -- DIFFERENT DAY
            p_address_snapshot      := '{"governorate": "القاهرة", "city": "مدينة نصر", "district": "المنطقة الأولى"}'::JSONB,
            p_service_snapshot      := '{"title": "خدمة يوم مختلف"}'::JSONB,
            p_pricing_inputs        := v_pricing_payload,
            p_contact_name          := 'العميل التجريبي - يوم مختلف',
            p_contact_phones        := ARRAY[v_test_phone],
            p_start_time_slot       := '10:00'
        );

        SELECT is_whatsapp_confirmed, status
        INTO v_b3_confirmed, v_b3_status
        FROM public.bookings
        WHERE id = v_booking_3_id;

        IF v_b3_confirmed = true AND v_b3_status = 'assigned' THEN
            INSERT INTO test_results VALUES (3, 'Test 3: Different Day Same Service', 'PASSED', 
                format('Confirmed normally as expected: status=%s, is_whatsapp_confirmed=true', v_b3_status));
        ELSE
            INSERT INTO test_results VALUES (3, 'Test 3: Different Day Same Service', 'FAILED', 
                format('Expected status=assigned & confirmed=true, got confirmed=%s, status=%s', v_b3_confirmed, v_b3_status));
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (3, 'Test 3: Different Day Same Service', 'ERROR', SQLERRM);
    END;

    -- ==========================================================================
    -- TEST 4: Same Day, Different Service (Must be normal confirmed booking)
    -- ==========================================================================
    BEGIN
        IF v_diff_service_id IS NOT NULL THEN
            v_booking_4_id := public.create_atomic_booking(
                p_user_id               := NULL,
                p_sub_service_id        := v_diff_service_id, -- DIFFERENT SERVICE
                p_technician_id         := NULL,
                p_scheduled_day         := v_test_day,        -- Same day
                p_address_snapshot      := '{"governorate": "القاهرة", "city": "مدينة نصر", "district": "المنطقة الأولى"}'::JSONB,
                p_service_snapshot      := '{"title": "خدمة مختلفة نفس اليوم"}'::JSONB,
                p_pricing_inputs        := v_pricing_payload,
                p_contact_name          := 'العميل التجريبي - خدمة مختلفة',
                p_contact_phones        := ARRAY[v_test_phone],
                p_start_time_slot       := '12:00'
            );

            SELECT is_whatsapp_confirmed, status
            INTO v_b4_confirmed, v_b4_status
            FROM public.bookings
            WHERE id = v_booking_4_id;

            IF v_b4_confirmed = true AND v_b4_status = 'assigned' THEN
                INSERT INTO test_results VALUES (4, 'Test 4: Same Day Different Service', 'PASSED', 
                    format('Confirmed normally as expected: status=%s, is_whatsapp_confirmed=true', v_b4_status));
            ELSE
                INSERT INTO test_results VALUES (4, 'Test 4: Same Day Different Service', 'FAILED', 
                    format('Expected status=assigned & confirmed=true, got confirmed=%s, status=%s', v_b4_confirmed, v_b4_status));
            END IF;
        ELSE
            INSERT INTO test_results VALUES (4, 'Test 4: Same Day Different Service', 'SKIPPED', 'No second bookable service with available technicians found in DB.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (4, 'Test 4: Same Day Different Service', 'ERROR', SQLERRM);
    END;

    -- ==========================================================================
    -- TEST 5: Direct Bypass Attempt via RPC (Must be blocked by Backend Authority)
    -- ==========================================================================
    BEGIN
        -- Client maliciously attempts to send p_is_whatsapp_confirmed := true for duplicate
        v_booking_5_id := public.create_atomic_booking(
            p_user_id               := NULL,
            p_sub_service_id        := v_service_id,
            p_technician_id         := NULL,
            p_scheduled_day         := v_test_day,
            p_address_snapshot      := '{"governorate": "القاهرة"}'::JSONB,
            p_service_snapshot      := '{"title": "خدمة تجاوز"}'::JSONB,
            p_pricing_inputs        := v_pricing_payload,
            p_contact_name          := 'العميل المخادع',
            p_contact_phones        := ARRAY[v_test_phone],
            p_is_whatsapp_confirmed := true -- Explicit bypass attempt!
        );

        SELECT is_whatsapp_confirmed, status
        INTO v_b5_confirmed, v_b5_status
        FROM public.bookings
        WHERE id = v_booking_5_id;

        IF v_b5_confirmed = false AND v_b5_status = 'created' THEN
            INSERT INTO test_results VALUES (5, 'Test 5: Direct Bypass Attempt (Backend Authority)', 'PASSED', 
                'Backend successfully overrode client parameter and enforced is_whatsapp_confirmed=false & status=created.');
        ELSE
            INSERT INTO test_results VALUES (5, 'Test 5: Direct Bypass Attempt (Backend Authority)', 'FAILED', 
                format('Bypass was allowed! confirmed=%s, status=%s', v_b5_confirmed, v_b5_status));
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (5, 'Test 5: Direct Bypass Attempt (Backend Authority)', 'ERROR', SQLERRM);
    END;

    -- ==========================================================================
    -- TEST 6: Secure Tracking RPC (Readable ID support & PII Masking)
    -- ==========================================================================
    BEGIN
        -- Search by Readable ID without phone (Unverified) -> PII masked
        v_guest_details := public.get_guest_booking_details(
            p_booking_id := v_readable_id,
            p_phone      := NULL
        );

        IF v_guest_details IS NOT NULL 
           AND (v_guest_details->>'is_phone_verified')::boolean = false
           AND v_guest_details->'contact_phones'->>0 LIKE '%****%' THEN
            INSERT INTO test_results VALUES (6, 'Test 6: Secure Guest Tracking RPC', 'PASSED', 
                format('Readable ID (%s) successfully queried, PII phones properly masked: %s', v_readable_id, v_guest_details->'contact_phones'->>0));
        ELSE
            INSERT INTO test_results VALUES (6, 'Test 6: Secure Guest Tracking RPC', 'FAILED', 
                format('Readable ID lookup or PII masking failed: %s', v_guest_details));
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (6, 'Test 6: Secure Guest Tracking RPC', 'ERROR', SQLERRM);
    END;

    -- ==========================================================================
    -- TEST 7: WhatsApp Confirmation Activation Flow (Dynamic Assignment)
    -- ==========================================================================
    BEGIN
        IF v_booking_2_id IS NOT NULL AND v_b2_token IS NOT NULL THEN
            -- Simulate customer confirming via WhatsApp token
            PERFORM public.confirm_whatsapp_booking(
                p_booking_id := v_booking_2_id,
                p_token      := v_b2_token
            );

            SELECT status, is_whatsapp_confirmed, technician_id
            INTO v_b2_after_status, v_b2_after_confirmed, v_b2_after_tech
            FROM public.bookings
            WHERE id = v_booking_2_id;

            IF v_b2_after_status = 'assigned' AND v_b2_after_confirmed = true THEN
                INSERT INTO test_results VALUES (7, 'Test 7: WhatsApp Confirmation Flow', 'PASSED', 
                    format('Successfully transitioned from created to assigned: confirmed=true, status=%s, tech_assigned=%s', 
                    v_b2_after_status, (v_b2_after_tech IS NOT NULL)::text));
            ELSE
                INSERT INTO test_results VALUES (7, 'Test 7: WhatsApp Confirmation Flow', 'FAILED', 
                    format('Expected status=assigned & confirmed=true, got status=%s, confirmed=%s', v_b2_after_status, v_b2_after_confirmed));
            END IF;
        ELSE
            INSERT INTO test_results VALUES (7, 'Test 7: WhatsApp Confirmation Flow', 'SKIPPED', 'Test 2 booking or token was not generated.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_results VALUES (7, 'Test 7: WhatsApp Confirmation Flow', 'ERROR', SQLERRM);
    END;

END;
$$;

SELECT test_id, test_name, status, details FROM test_results ORDER BY test_id;

-- Rollback mutations so database remains 100% clean
ROLLBACK;
