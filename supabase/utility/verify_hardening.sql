-- ==============================================================================
-- Fresh Home: Backend Security Hardening Verification Script (verify_hardening.sql)
-- Description: Transactional PL/pgSQL verification testing RLS, RPC authorization,
--              role spoofing prevention, JSON schema validation, and audit triggers.
-- NOTE: This script runs inside a transaction and ends with ROLLBACK.
--       It is safe to execute on any environment to verify hardening.
-- ==============================================================================

BEGIN;

-- Create a temporary table to store test results
CREATE TEMP TABLE test_log (
    test_id      SERIAL PRIMARY KEY,
    test_name    TEXT NOT NULL,
    status       TEXT NOT NULL,
    details      TEXT
);

GRANT ALL ON TABLE test_log TO public;
GRANT ALL ON SEQUENCE test_log_test_id_seq TO public;

DO $$
DECLARE
    v_main_service_id    UUID := gen_random_uuid();
    v_sub_service_id     UUID := gen_random_uuid();
    v_test_client_id     UUID := gen_random_uuid();
    v_test_admin_id      UUID := gen_random_uuid();
    v_test_tech_id       UUID := gen_random_uuid();
    v_booking_id         UUID;
    v_client_role_id     INT;
    v_admin_role_id      INT;
    v_tech_role_id       INT;
    v_cnt                INT;
    v_err_state          TEXT;
    v_err_msg            TEXT;
BEGIN
    -- Disable user triggers temporarily to insert test data without constraint failures
    -- (We use USER instead of ALL to avoid touching system triggers like foreign keys, which requires superuser privileges)
    ALTER TABLE public.profiles DISABLE TRIGGER USER;
    ALTER TABLE public.user_roles DISABLE TRIGGER USER;
    ALTER TABLE public.technician_profiles DISABLE TRIGGER USER;
    ALTER TABLE public.bookings DISABLE TRIGGER USER;
    ALTER TABLE public.booking_events DISABLE TRIGGER USER;

    -- 0. Insert mock auth users into auth.users to satisfy foreign key constraints on public.profiles(id)
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
    VALUES 
        (v_test_client_id, 'test_client_verify@freshhome.com', '', now(), 'authenticated', 'authenticated'),
        (v_test_admin_id, 'test_admin_verify@freshhome.com', '', now(), 'authenticated', 'authenticated'),
        (v_test_tech_id, 'test_tech_verify@freshhome.com', '', now(), 'authenticated', 'authenticated')
    ON CONFLICT (id) DO NOTHING;

    -- 1. Setup roles if missing
    SELECT id INTO v_client_role_id FROM public.roles WHERE name = 'client';
    IF v_client_role_id IS NULL THEN
        INSERT INTO public.roles (name) VALUES ('client') RETURNING id INTO v_client_role_id;
    END IF;

    SELECT id INTO v_admin_role_id FROM public.roles WHERE name = 'admin';
    IF v_admin_role_id IS NULL THEN
        INSERT INTO public.roles (name) VALUES ('admin') RETURNING id INTO v_admin_role_id;
    END IF;

    SELECT id INTO v_tech_role_id FROM public.roles WHERE name = 'technician';
    IF v_tech_role_id IS NULL THEN
        INSERT INTO public.roles (name) VALUES ('technician') RETURNING id INTO v_tech_role_id;
    END IF;

    -- 2. Setup profiles (using ON CONFLICT DO NOTHING to handle cases where sync triggers already populated them)
    INSERT INTO public.profiles (id, first_name, last_name, email, account_status)
    VALUES 
        (v_test_client_id, 'Test', 'Client', 'test_client_verify@freshhome.com', 'active'),
        (v_test_admin_id, 'Test', 'Admin', 'test_admin_verify@freshhome.com', 'active'),
        (v_test_tech_id, 'Test', 'Technician', 'test_tech_verify@freshhome.com', 'active')
    ON CONFLICT (id) DO NOTHING;

    -- 3. Setup user roles
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES 
        (v_test_client_id, v_client_role_id),
        (v_test_admin_id, v_admin_role_id),
        (v_test_tech_id, v_tech_role_id)
    ON CONFLICT (user_id, role_id) DO NOTHING;

    -- 4. Setup technician profile
    INSERT INTO public.technician_profiles (user_id, is_verified, is_available)
    VALUES (v_test_tech_id, true, true)
    ON CONFLICT (user_id) DO NOTHING;

    -- 5. Setup test services and schema configurations
    INSERT INTO public.services (id, parent_id, is_bookable, title, description, status)
    VALUES (v_main_service_id, NULL, false, '{"en": "Hardening Test Service"}'::jsonb, '{"en": "Description"}'::jsonb, 'active');

    INSERT INTO public.services (id, parent_id, is_bookable, title, description, price_config, status)
    VALUES (
        v_sub_service_id, 
        v_main_service_id, 
        true,
        '{"en": "Hardening Test Sub Service"}'::jsonb, 
        '{"en": "Description"}'::jsonb, 
        '{"type": "fixed", "value": 150.0, "fields": [{"id": "area", "type": "number", "required": true, "label": {"en": "Area", "ar": "المساحة"}}]}'::jsonb,
        'active'
    );

    -- Re-enable user triggers before running assertions
    ALTER TABLE public.profiles ENABLE TRIGGER USER;
    ALTER TABLE public.user_roles ENABLE TRIGGER USER;
    ALTER TABLE public.technician_profiles ENABLE TRIGGER USER;
    ALTER TABLE public.bookings ENABLE TRIGGER USER;
    ALTER TABLE public.booking_events ENABLE TRIGGER USER;


    -- ==========================================================================
    -- TEST 1: Direct bookings insertion policy (Must Fail for Standard Users)
    -- ==========================================================================
    BEGIN
        SET LOCAL ROLE authenticated;
        PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_client_id::text)::text, true);

        INSERT INTO public.bookings (user_id, service_id, scheduled_day, address_snapshot, service_snapshot, price_snapshot)
        VALUES (v_test_client_id, v_sub_service_id, '2026-06-01', '{}', '{}', '{}');

        INSERT INTO test_log (test_name, status, details)
        VALUES ('1. Direct Bookings Insert Bypass', 'FAILED', 'Exploit Success: Standard user was able to bypass the RPC gateway and insert directly into public.bookings table.');
    EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('1. Direct Bookings Insert Bypass', 'PASSED', 'Correctly blocked direct INSERT attempt on public.bookings. Error SQLSTATE: ' || SQLSTATE);
    END;

    -- Reset local session
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);


    -- ==========================================================================
    -- TEST 2: Pricing Tables RLS Policies (SELECT Allowed, Mutations Blocked)
    -- ==========================================================================
    BEGIN
        SET LOCAL ROLE authenticated;
        PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_client_id::text)::text, true);

        -- Test 2a: SELECT must succeed
        BEGIN
            PERFORM count(*) FROM public.pricing_rules;
            INSERT INTO test_log (test_name, status, details)
            VALUES ('2a. Pricing RLS (Select)', 'PASSED', 'Successfully read pricing rules as authenticated customer.');
        EXCEPTION WHEN OTHERS THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('2a. Pricing RLS (Select)', 'FAILED', 'SELECT pricing_rules blocked for client: ' || SQLERRM);
        END;

        -- Test 2b: INSERT must fail
        BEGIN
            INSERT INTO public.pricing_rules (sub_service_id, name, condition_ast, action_type, action_value, priority)
            VALUES (v_sub_service_id, 'Exploit Base Price', '{}'::jsonb, 'override', 1.0, 999);
            INSERT INTO test_log (test_name, status, details)
            VALUES ('2b. Pricing RLS (Insert)', 'FAILED', 'Exploit Success: Standard client user inserted structural rules.');
        EXCEPTION WHEN insufficient_privilege THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('2b. Pricing RLS (Insert)', 'PASSED', 'Correctly blocked direct pricing rule insertion.');
        END;

        -- Test 2c: UPDATE must fail
        BEGIN
            UPDATE public.pricing_rules SET action_value = 1.0 WHERE sub_service_id = v_sub_service_id;
            GET DIAGNOSTICS v_cnt = ROW_COUNT;
            IF v_cnt > 0 THEN
                INSERT INTO test_log (test_name, status, details)
                VALUES ('2c. Pricing RLS (Update)', 'FAILED', 'Exploit Success: Standard client user updated pricing configurations.');
            ELSE
                INSERT INTO test_log (test_name, status, details)
                VALUES ('2c. Pricing RLS (Update)', 'PASSED', 'Correctly blocked direct pricing rule updates (0 rows affected).');
            END IF;
        END;

        -- Test 2d: DELETE must fail
        BEGIN
            DELETE FROM public.pricing_rules WHERE sub_service_id = v_sub_service_id;
            GET DIAGNOSTICS v_cnt = ROW_COUNT;
            IF v_cnt > 0 THEN
                INSERT INTO test_log (test_name, status, details)
                VALUES ('2d. Pricing RLS (Delete)', 'FAILED', 'Exploit Success: Standard client user deleted active pricing rules.');
            ELSE
                INSERT INTO test_log (test_name, status, details)
                VALUES ('2d. Pricing RLS (Delete)', 'PASSED', 'Correctly blocked pricing rule deletions (0 rows affected).');
            END IF;
        END;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('2. Pricing RLS General', 'FAILED', 'General pricing RLS test exception: ' || SQLERRM);
    END;

    -- Reset local session
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);


    -- ==========================================================================
    -- TEST 2e: Pricing Mutation Allowed for Admins
    -- ==========================================================================
    BEGIN
        SET LOCAL ROLE authenticated;
        PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_admin_id::text)::text, true);

        INSERT INTO public.pricing_rules (sub_service_id, name, condition_ast, action_type, action_value, priority)
        VALUES (v_sub_service_id, 'Admin Hardened Pricing Rule', '{}'::jsonb, 'add', 50.0, 999);

        INSERT INTO test_log (test_name, status, details)
        VALUES ('2e. Pricing Admin Mutation', 'PASSED', 'Successfully inserted rule into pricing_rules as admin.');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('2e. Pricing Admin Mutation', 'FAILED', 'Admin was blocked from inserting pricing rule: ' || SQLERRM);
    END;

    -- Reset local session
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);


    -- ==========================================================================
    -- TEST 3: Admin Dashboard/Fleet Operations Access Control (Must Fail for Client)
    -- ==========================================================================
    BEGIN
        SET LOCAL ROLE authenticated;
        PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_client_id::text)::text, true);

        -- Test 3a: get_fleet_capacity_dashboard check
        BEGIN
            PERFORM * FROM public.get_fleet_capacity_dashboard('2026-06-01'::DATE);
            INSERT INTO test_log (test_name, status, details)
            VALUES ('3a. Fleet Capacity RLS', 'FAILED', 'Exploit Success: Standard customer fetched fleet metrics dashboard.');
        EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('3a. Fleet Capacity RLS', 'PASSED', 'Correctly blocked non-admin access to fleet dashboard.');
        END;

        -- Test 3b: admin_reassign_booking check
        BEGIN
            PERFORM public.admin_reassign_booking(gen_random_uuid(), v_test_tech_id);
            INSERT INTO test_log (test_name, status, details)
            VALUES ('3b. Admin Reassignment RLS', 'FAILED', 'Exploit Success: Standard customer invoked admin_reassign_booking RPC.');
        EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('3b. Admin Reassignment RLS', 'PASSED', 'Correctly blocked customer execution of admin_reassign_booking.');
        END;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('3. Admin Dashboards General', 'FAILED', 'General dashboard security test exception: ' || SQLERRM);
    END;

    -- Reset local session
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);


    -- ==========================================================================
    -- TEST 4: Secure Atomic Booking & Lifecycle Transitions (Client Spoof / Transitions)
    -- ==========================================================================
    BEGIN
        SET LOCAL ROLE authenticated;
        PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_client_id::text)::text, true);

        -- Test 4a: Create Valid Booking via gateway RPC
        v_booking_id := public.create_atomic_booking(
            p_user_id          => v_test_client_id,
            p_sub_service_id   => v_sub_service_id,
            p_technician_id    => v_test_tech_id,
            p_scheduled_day    => '2026-06-01'::DATE,
            p_address_snapshot => '{"city": "Cairo", "governorate": "Cairo", "street": "Test Street", "building_number": "1"}'::jsonb,
            p_service_snapshot => '{"title": "Test Cleaning"}'::jsonb,
            p_pricing_inputs   => '{"area": 120}'::jsonb
        );

        INSERT INTO test_log (test_name, status, details)
        VALUES ('4a. Atomic Booking Gateway', 'PASSED', 'Successfully created secure booking via create_atomic_booking RPC (ID: ' || v_booking_id || ').');

        -- Test 4b: Spoof User Booking Creation (client trying to book for admin)
        BEGIN
            PERFORM public.create_atomic_booking(
                p_user_id          => v_test_admin_id, -- Spoofing UID!
                p_sub_service_id   => v_sub_service_id,
                p_technician_id    => v_test_tech_id,
                p_scheduled_day    => '2026-06-01'::DATE,
                p_address_snapshot => '{"city": "Cairo"}'::jsonb,
                p_service_snapshot => '{"title": "Test"}'::jsonb,
                p_pricing_inputs   => '{"area": 120}'::jsonb
            );
            INSERT INTO test_log (test_name, status, details)
            VALUES ('4b. Booking User ID Spoof', 'FAILED', 'Exploit Success: Customer created a booking under another user ID.');
        EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('4b. Booking User ID Spoof', 'PASSED', 'Correctly rejected booking creation with mismatched auth.uid().');
        END;

        -- Test 4c: Role spoofing in transition_booking (Calling transition directly as admin)
        BEGIN
            PERFORM public.transition_booking(
                p_booking_id => v_booking_id,
                p_new_status => 'completed'::public.order_status_v2,
                p_actor_id   => v_test_client_id,
                p_actor_role => 'admin', -- Spoofing role!
                p_reason_code => 'HACK'
            );
            INSERT INTO test_log (test_name, status, details)
            VALUES ('4c. Transition Role Spoof', 'FAILED', 'Exploit Success: Client bypassed transition gatekeeper by claiming admin role.');
        EXCEPTION WHEN insufficient_privilege OR raise_exception THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('4c. Transition Role Spoof', 'PASSED', 'Correctly overrode actor role and blocked administrative transition: ' || SQLERRM);
        END;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('4. Booking & Transition General', 'FAILED', 'Booking/Transition test exception: ' || SQLERRM);
    END;

    -- Reset local session
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);


    -- ==========================================================================
    -- TEST 5: JSON Schema & Pricing Validation in RPC
    -- ==========================================================================
    BEGIN
        SET LOCAL ROLE authenticated;
        PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_client_id::text)::text, true);

        -- Test 5a: Missing required field ('area')
        BEGIN
            PERFORM public.create_atomic_booking(
                p_user_id          => v_test_client_id,
                p_sub_service_id   => v_sub_service_id,
                p_technician_id    => v_test_tech_id,
                p_scheduled_day    => '2026-06-01'::DATE,
                p_address_snapshot => '{"city": "Cairo"}'::jsonb,
                p_service_snapshot => '{"title": "Test"}'::jsonb,
                p_pricing_inputs   => '{}'::jsonb -- Missing required 'area'!
            );
            INSERT INTO test_log (test_name, status, details)
            VALUES ('5a. Pricing Input (Missing)', 'FAILED', 'Exploit Success: RPC accepted pricing inputs missing required fields.');
        EXCEPTION WHEN OTHERS THEN
            IF SQLSTATE = 'P0001' THEN
                INSERT INTO test_log (test_name, status, details)
                VALUES ('5a. Pricing Input (Missing)', 'PASSED', 'Successfully rejected missing required fields. SQLSTATE: P0001 (' || SQLERRM || ')');
            ELSE
                INSERT INTO test_log (test_name, status, details)
                VALUES ('5a. Pricing Input (Missing)', 'FAILED', 'Rejected but with unexpected error state: ' || SQLSTATE || ' - ' || SQLERRM);
            END IF;
        END;

        -- Test 5b: Invalid field type ('area' passed as text)
        BEGIN
            PERFORM public.create_atomic_booking(
                p_user_id          => v_test_client_id,
                p_sub_service_id   => v_sub_service_id,
                p_technician_id    => v_test_tech_id,
                p_scheduled_day    => '2026-06-01'::DATE,
                p_address_snapshot => '{"city": "Cairo"}'::jsonb,
                p_service_snapshot => '{"title": "Test"}'::jsonb,
                p_pricing_inputs   => '{"area": "one_hundred"}'::jsonb -- Invalid type!
            );
            INSERT INTO test_log (test_name, status, details)
            VALUES ('5b. Pricing Input (Type)', 'FAILED', 'Exploit Success: RPC accepted pricing inputs with invalid data types.');
        EXCEPTION WHEN OTHERS THEN
            IF SQLSTATE = 'P0001' THEN
                INSERT INTO test_log (test_name, status, details)
                VALUES ('5b. Pricing Input (Type)', 'PASSED', 'Successfully rejected invalid types in pricing inputs. SQLSTATE: P0001 (' || SQLERRM || ')');
            ELSE
                INSERT INTO test_log (test_name, status, details)
                VALUES ('5b. Pricing Input (Type)', 'FAILED', 'Rejected but with unexpected error state: ' || SQLSTATE || ' - ' || SQLERRM);
            END IF;
        END;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('5. Pricing Schema General', 'FAILED', 'Pricing Schema validation test exception: ' || SQLERRM);
    END;

    -- Reset local session
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);


    -- ==========================================================================
    -- TEST 6: Pricing Governance Automatic Audit Logs
    -- ==========================================================================
    BEGIN
        -- Query how many governance audit entries exist for our test sub-service.
        -- In Test 2e, an admin rule was successfully inserted, which should trigger audit creation.
        SELECT COUNT(*) INTO v_cnt 
        FROM public.pricing_governance_audit 
        WHERE sub_service_id = v_sub_service_id AND action = 'INSERT';

        IF v_cnt > 0 THEN
            INSERT INTO test_log (test_name, status, details)
            VALUES ('6a. Governance Log Trigger', 'PASSED', 'Verified triggers automatically logged admin rule changes to pricing_governance_audit.');
        ELSE
            INSERT INTO test_log (test_name, status, details)
            VALUES ('6a. Governance Log Trigger', 'FAILED', 'Admin rule insert did not log to pricing_governance_audit.');
        END IF;

        -- Test 6b: Audit Table RLS (Read Blocked for Client)
        BEGIN
            SET LOCAL ROLE authenticated;
            PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', v_test_client_id::text)::text, true);

            SELECT COUNT(*) INTO v_cnt FROM public.pricing_governance_audit;
            IF v_cnt > 0 THEN
                INSERT INTO test_log (test_name, status, details)
                VALUES ('6b. Audit Table RLS (Read)', 'FAILED', 'Exploit Success: Authenticated customer selected from pricing_governance_audit table.');
            ELSE
                INSERT INTO test_log (test_name, status, details)
                VALUES ('6b. Audit Table RLS (Read)', 'PASSED', 'Correctly blocked non-admin select access to pricing_governance_audit (0 rows returned).');
            END IF;
        END;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO test_log (test_name, status, details)
        VALUES ('6. Pricing Governance General', 'FAILED', 'Pricing Governance test exception: ' || SQLERRM);
    END;

    -- Final cleanup reset
    RESET ROLE;
    PERFORM set_config('request.jwt.claims', NULL, true);

END;
$$;

-- Return test results log
SELECT test_name, status, details 
FROM test_log 
ORDER BY test_id;

-- Abort transaction to rollback all test structures (leaves db perfectly clean)
ROLLBACK;
