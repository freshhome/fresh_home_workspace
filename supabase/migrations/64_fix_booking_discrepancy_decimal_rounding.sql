-- Migration ID: 64_fix_booking_discrepancy_decimal_rounding
-- Description: Fix discrepancy comparison by comparing truncated amounts (ignoring decimal fractions).

BEGIN;

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
    
    v_running_balance_1 NUMERIC(12,2);
    v_running_balance_2 NUMERIC(12,2);
    
    v_commission_ref_id UUID;
BEGIN
    -- Only run for completed bookings with a assigned technician
    IF NEW.technician_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Concurrency Guard: Lock the technician account row for update
    SELECT id, amount_owed_to_company, amount_owed_to_technician, net_balance
    INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance
    FROM public.technician_financial_accounts
    WHERE technician_id = NEW.technician_id
    FOR UPDATE;

    -- Proactive Account Registration: Create account if not exists
    IF NOT FOUND THEN
        INSERT INTO public.technician_financial_accounts (technician_id)
        VALUES (NEW.technician_id)
        RETURNING id, amount_owed_to_company, amount_owed_to_technician, net_balance
        INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance;
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

    -- Handle cash payments vs online payments
    IF COALESCE(NEW.payment_method, 'cash') = 'cash' THEN
        -- Cash Orders
        -- Securely parse actual collected amount from pricing_inputs JSONB field
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
            -- We debit the total collected cash because they kept the cash.
            -- This sets a debt liability for the full amount offset by the earnings.
            v_running_balance_2 := v_running_balance_1 - v_expected_amount;
            -- Generate a unique deterministic UUID based on booking ID for the second entry
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
        -- Online Orders (online_card, etc.)
        -- Generate one ledger entry: order_earnings (credit = technician_payout)
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
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMIT;
