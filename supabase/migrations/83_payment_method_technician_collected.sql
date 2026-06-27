-- Migration ID: 83_payment_method_technician_collected
-- Description: Align pricing & payment calculations with Technician-Collected flow. Updates ledger trigger condition and automates case resolution ledger generation.

BEGIN;

-- 1. Update public.create_atomic_booking to insert payment_method column from pricing_inputs JSONB
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
        whatsapp_confirmation_token,
        payment_method
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, v_price_snapshot,
        COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2,
        p_is_whatsapp_confirmed,
        CASE WHEN NOT p_is_whatsapp_confirmed THEN NOW() + (v_expiry_minutes || ' minutes')::interval ELSE NULL END,
        gen_random_uuid(),
        COALESCE(p_pricing_inputs ->> 'payment_method', 'cash')
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


-- 2. Update public.fn_automate_booking_ledger_entry trigger function to treat instapay and vodafone_cash as cash (technician-collected)
CREATE OR REPLACE FUNCTION public.fn_automate_booking_ledger_entry()
RETURNS TRIGGER AS $$
DECLARE
    v_account_id UUID;
    v_amount_owed_to_company NUMERIC(12,2);
    v_amount_owed_to_technician NUMERIC(12,2);
    v_net_balance NUMERIC(12,2);
    
    v_expected_amount NUMERIC(12,2);
    v_collected_amount NUMERIC(12,2);
    v_platform_commission NUMERIC(12,2);
    v_technician_payout NUMERIC(12,2);
    v_commission_rate NUMERIC;
    
    v_running_balance_1 NUMERIC(12,2);
    v_running_balance_2 NUMERIC(12,2);
    
    v_commission_ref_id UUID;
BEGIN
    -- Only run for completed bookings with an assigned technician
    IF NEW.technician_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Securely parse and validate expected price snapshot fields
    BEGIN
        v_expected_amount := (NEW.price_snapshot ->> 'total')::NUMERIC;
    EXCEPTION WHEN OTHERS THEN
        v_expected_amount := 0.00;
    END;

    BEGIN
        v_platform_commission := (NEW.price_snapshot -> 'metadata' ->> 'platform_commission')::NUMERIC;
    EXCEPTION WHEN OTHERS THEN
        v_platform_commission := 0.00;
    END;

    BEGIN
        v_technician_payout := (NEW.price_snapshot -> 'metadata' ->> 'technician_payout')::NUMERIC;
    EXCEPTION WHEN OTHERS THEN
        v_technician_payout := 0.00;
    END;

    -- Fallback default values
    IF v_expected_amount IS NULL THEN v_expected_amount := 0.00; END IF;
    IF v_platform_commission IS NULL THEN v_platform_commission := 0.00; END IF;
    IF v_technician_payout IS NULL THEN v_technician_payout := 0.00; END IF;

    -- Fallback calculation if metadata values are missing or zero but expected_amount is greater than zero
    IF v_expected_amount > 0.00 AND (v_technician_payout = 0.00 OR v_platform_commission = 0.00) THEN
        SELECT COALESCE(s.commission_rate, 0.20) INTO v_commission_rate
        FROM public.services s
        WHERE s.id = NEW.service_id;

        IF v_commission_rate IS NULL THEN v_commission_rate := 0.20; END IF;

        IF v_platform_commission = 0.00 THEN
            v_platform_commission := v_expected_amount * v_commission_rate;
        END IF;
        IF v_technician_payout = 0.00 THEN
            v_technician_payout := v_expected_amount * (1.0 - v_commission_rate);
        END IF;
    END IF;

    -- Bypass zero-value transactions (e.g. 100% discount free coupon codes)
    IF v_expected_amount = 0.00 AND v_technician_payout = 0.00 THEN
        RETURN NEW;
    END IF;

    -- Concurrency Guard: Lock the technician account row for update
    SELECT id, amount_owed_to_company, amount_owed_to_technician, net_balance
    INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance
    FROM public.technician_financial_accounts
    WHERE technician_id = NEW.technician_id
    FOR UPDATE;

    -- Enforce strict architectural flow: raise error if account does not exist
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Technician financial account not found for ID %', NEW.technician_id USING ERRCODE = 'P0002';
    END IF;

    -- Handle cash payments vs online payments (treating cash, instapay, vodafone_cash identically as technician-collected)
    IF COALESCE(NEW.payment_method, 'cash') IN ('cash', 'instapay', 'vodafone_cash') THEN
        -- Cash and other technician-collected orders
        BEGIN
            v_collected_amount := (NEW.pricing_inputs ->> 'collected_amount')::NUMERIC;
        EXCEPTION WHEN OTHERS THEN
            v_collected_amount := 0.00;
        END;
        
        IF v_collected_amount IS NULL THEN v_collected_amount := 0.00; END IF;

        -- We compare the truncated values (ignoring decimal fractions) to support technician cash rounding inputs
        IF TRUNC(v_collected_amount) = TRUNC(v_expected_amount) THEN
            -- Matches perfectly: Generate two ledger entries in order

            -- 1. order_earnings (credit = technician_payout)
            v_running_balance_1 := v_net_balance + v_technician_payout;
            INSERT INTO public.ledger_entries (
                account_id, booking_id, entry_type, debit, credit, running_balance, 
                description, reference_id, reference_type
            ) VALUES (
                v_account_id, NEW.id, 'order_earnings', 0.00, v_technician_payout, v_running_balance_1,
                'أرباح الفني من الطلب النقدي #' || NEW.readable_id, NEW.id, 'booking'
            );

            -- 2. company_commission_debit (debit = total)
            v_running_balance_2 := v_running_balance_1 - v_expected_amount;
            v_commission_ref_id := cast(md5('commission/' || NEW.id::text) as uuid);
            
            INSERT INTO public.ledger_entries (
                account_id, booking_id, entry_type, debit, credit, running_balance, 
                description, reference_id, reference_type
            ) VALUES (
                v_account_id, NEW.id, 'company_commission_debit', v_expected_amount, 0.00, v_running_balance_2,
                'خصم عمولة وإجمالي تحصيل كاش للطلب #' || NEW.readable_id, v_commission_ref_id, 'booking'
            );

            -- Update technician financial account
            UPDATE public.technician_financial_accounts
            SET 
                amount_owed_to_company = amount_owed_to_company + v_expected_amount,
                amount_owed_to_technician = amount_owed_to_technician + v_technician_payout,
                updated_at = NOW()
            WHERE id = v_account_id;

        ELSE
            -- Discrepancy detected: INSERT a record into financial_cases
            INSERT INTO public.financial_cases (
                booking_id, reported_by, discrepancy_type, expected_amount, collected_amount, 
                description, status
            ) VALUES (
                NEW.id, NEW.technician_id, 'collection_discrepancy'::public.financial_case_type, v_expected_amount, v_collected_amount,
                'وجود فرق تحصيل نقدي: المبلغ المتوقع ' || v_expected_amount::TEXT || ' والمحصل ' || v_collected_amount::TEXT,
                'pending_review'::public.financial_case_status
            );
        END IF;

    ELSE
        -- True Online Orders (Direct platform payments, future phase)
        v_running_balance_1 := v_net_balance + v_technician_payout;
        INSERT INTO public.ledger_entries (
            account_id, booking_id, entry_type, debit, credit, running_balance, 
            description, reference_id, reference_type
        ) VALUES (
            v_account_id, NEW.id, 'order_earnings', 0.00, v_technician_payout, v_running_balance_1,
            'أرباح الفني من الدفع الإلكتروني للطلب #' || NEW.readable_id, NEW.id, 'booking'
        );

        -- Update technician financial account
        UPDATE public.technician_financial_accounts
        SET 
            amount_owed_to_technician = amount_owed_to_technician + v_technician_payout,
            updated_at = NOW()
        WHERE id = v_account_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;


-- 3. Create Case Resolution trigger function to automatically write ledger entries when a case is resolved by an admin
CREATE OR REPLACE FUNCTION public.fn_automate_financial_case_resolution()
RETURNS TRIGGER AS $$
DECLARE
    v_booking RECORD;
    v_account_id UUID;
    v_amount_owed_to_company NUMERIC(12,2);
    v_amount_owed_to_technician NUMERIC(12,2);
    v_net_balance NUMERIC(12,2);
    
    v_expected_amount NUMERIC(12,2);
    v_collected_amount NUMERIC(12,2);
    v_platform_commission NUMERIC(12,2);
    v_technician_payout NUMERIC(12,2);
    v_commission_rate NUMERIC;
    
    v_running_balance_1 NUMERIC(12,2);
    v_running_balance_2 NUMERIC(12,2);
    
    v_commission_ref_id UUID;
BEGIN
    -- Only trigger when case status becomes 'resolved'
    IF NEW.status = 'resolved'::public.financial_case_status AND OLD.status IS DISTINCT FROM 'resolved'::public.financial_case_status THEN
        
        -- Load booking details
        SELECT * INTO v_booking FROM public.bookings WHERE id = NEW.booking_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Booking not found for ID %', NEW.booking_id USING ERRCODE = 'P0002';
        END IF;

        IF v_booking.technician_id IS NULL THEN
            RETURN NEW;
        END IF;

        -- Concurrency Guard: Lock the technician account for update
        SELECT id, amount_owed_to_company, amount_owed_to_technician, net_balance
        INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance
        FROM public.technician_financial_accounts
        WHERE technician_id = v_booking.technician_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Technician financial account not found for ID %', v_booking.technician_id USING ERRCODE = 'P0002';
        END IF;

        -- Parse snapshots
        BEGIN
            v_expected_amount := (v_booking.price_snapshot ->> 'total')::NUMERIC;
        EXCEPTION WHEN OTHERS THEN
            v_expected_amount := 0.00;
        END;

        BEGIN
            v_platform_commission := (v_booking.price_snapshot -> 'metadata' ->> 'platform_commission')::NUMERIC;
        EXCEPTION WHEN OTHERS THEN
            v_platform_commission := 0.00;
        END;

        BEGIN
            v_technician_payout := (v_booking.price_snapshot -> 'metadata' ->> 'technician_payout')::NUMERIC;
        EXCEPTION WHEN OTHERS THEN
            v_technician_payout := 0.00;
        END;

        IF v_expected_amount IS NULL THEN v_expected_amount := 0.00; END IF;
        IF v_platform_commission IS NULL THEN v_platform_commission := 0.00; END IF;
        IF v_technician_payout IS NULL THEN v_technician_payout := 0.00; END IF;

        -- Set the resolved collected amount
        v_collected_amount := NEW.collected_amount;

        -- Fallback calculations if metadata values are missing or zero but expected is greater than zero
        IF v_expected_amount > 0.00 AND (v_technician_payout = 0.00 OR v_platform_commission = 0.00) THEN
            SELECT COALESCE(s.commission_rate, 0.20) INTO v_commission_rate
            FROM public.services s
            WHERE s.id = v_booking.service_id;

            IF v_commission_rate IS NULL THEN v_commission_rate := 0.20; END IF;

            IF v_platform_commission = 0.00 THEN
                v_platform_commission := v_expected_amount * v_commission_rate;
            END IF;
            IF v_technician_payout = 0.00 THEN
                v_technician_payout := v_expected_amount * (1.0 - v_commission_rate);
            END IF;
        END IF;

        -- Scale platform commission and technician payout proportionally based on the resolved collected amount
        IF v_expected_amount > 0.00 THEN
            v_platform_commission := (v_platform_commission * v_collected_amount) / v_expected_amount;
            v_technician_payout := (v_technician_payout * v_collected_amount) / v_expected_amount;
        ELSE
            v_platform_commission := 0.00;
            v_technician_payout := 0.00;
        END IF;

        -- 1. order_earnings (credit = technician_payout)
        v_running_balance_1 := v_net_balance + v_technician_payout;
        INSERT INTO public.ledger_entries (
            account_id, booking_id, entry_type, debit, credit, running_balance, 
            description, reference_id, reference_type, created_by
        ) VALUES (
            v_account_id, v_booking.id, 'order_earnings', 0.00, v_technician_payout, v_running_balance_1,
            'أرباح الفني من تسوية نزاع التحصيل للطلب #' || v_booking.readable_id, v_booking.id, 'booking', NEW.resolved_by
        );

        -- 2. company_commission_debit (debit = collected_amount)
        v_running_balance_2 := v_running_balance_1 - v_collected_amount;
        v_commission_ref_id := cast(md5('commission/' || v_booking.id::text) as uuid);
        
        INSERT INTO public.ledger_entries (
            account_id, booking_id, entry_type, debit, credit, running_balance, 
            description, reference_id, reference_type, created_by
        ) VALUES (
            v_account_id, v_booking.id, 'company_commission_debit', v_collected_amount, 0.00, v_running_balance_2,
            'عمولة وإجمالي تحصيل كاش لتسوية نزاع الطلب #' || v_booking.readable_id, v_commission_ref_id, 'booking', NEW.resolved_by
        );

        -- Update technician financial account
        UPDATE public.technician_financial_accounts
        SET 
            amount_owed_to_company = amount_owed_to_company + v_collected_amount,
            amount_owed_to_technician = amount_owed_to_technician + v_technician_payout,
            updated_at = NOW()
        WHERE id = v_account_id;

        -- Log case event
        INSERT INTO public.financial_case_events (case_id, event_type, actor_id, notes)
        VALUES (
            NEW.id,
            'case_resolved_ledger_written',
            NEW.resolved_by,
            'تم تسجيل قيود المحاسبة تلقائياً بعد حل نزاع التحصيل بمبلغ ' || v_collected_amount::TEXT
        );

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;

-- Attach Case Resolution trigger
DROP TRIGGER IF EXISTS trg_automate_financial_case_resolution ON public.financial_cases;
CREATE TRIGGER trg_automate_financial_case_resolution
AFTER UPDATE OF status ON public.financial_cases
FOR EACH ROW
EXECUTE FUNCTION public.fn_automate_financial_case_resolution();

COMMIT;
