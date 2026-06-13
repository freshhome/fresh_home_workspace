-- ==============================================================================
-- Fresh Home: Financial Audit Urgent Hotfixes
-- Migration ID: 68_apply_financial_audit_hotfixes
-- Description: Fixes Concurrency (Risk 3), Zero-Value Crash (Risk 4), and Security (Risk 5).
-- ==============================================================================

BEGIN;

-- ── 1. FIX RISK 3: CONCURRENCY ON ACCOUNT CREATION ────────────────────────────

-- Trigger function to automatically create a financial account when a technician profile is registered
CREATE OR REPLACE FUNCTION public.fn_create_technician_financial_account()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.technician_financial_accounts (technician_id)
    VALUES (NEW.user_id)
    ON CONFLICT (technician_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Attach trigger to public.technician_profiles (AFTER INSERT)
DROP TRIGGER IF EXISTS trg_create_technician_financial_account ON public.technician_profiles;
CREATE TRIGGER trg_create_technician_financial_account
AFTER INSERT ON public.technician_profiles
FOR EACH ROW
EXECUTE FUNCTION public.fn_create_technician_financial_account();

-- Backfill: Proactively create accounts for any existing technicians who don't have one yet
INSERT INTO public.technician_financial_accounts (technician_id)
SELECT user_id FROM public.technician_profiles
ON CONFLICT (technician_id) DO NOTHING;


-- ── 2. FIX RISK 5: SECURE FUNCTIONS WITH SEARCH PATH ───────────────────────────

-- Recreate is_admin with secure search path
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() 
          AND r.name = 'admin'
      -- Explicitly target public schema for roles tables to prevent hijacking
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public STABLE;

-- Recreate fn_recalculate_account_status with secure search path
CREATE OR REPLACE FUNCTION public.fn_recalculate_account_status()
RETURNS TRIGGER AS $$
DECLARE
    v_ratio NUMERIC;
    v_net_debt NUMERIC;
BEGIN
    IF NEW.debt_limit IS NULL OR NEW.debt_limit = 0.00 THEN
        NEW.account_status := 'active'::public.financial_account_status;
    ELSE
        -- Net debt = what technician owes to company minus what company owes to technician
        v_net_debt := NEW.amount_owed_to_company - NEW.amount_owed_to_technician;
        
        IF v_net_debt <= 0.00 THEN
            NEW.account_status := 'active'::public.financial_account_status;
        ELSE
            v_ratio := v_net_debt / NEW.debt_limit;
            
            IF v_ratio < 0.80 THEN
                NEW.account_status := 'active'::public.financial_account_status;
            ELSIF v_ratio >= 0.80 AND v_ratio < 1.00 THEN
                NEW.account_status := 'restricted'::public.financial_account_status;
            ELSE
                NEW.account_status := 'blocked'::public.financial_account_status;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;

-- Recreate fn_automate_adjustment_ledger_entry with secure search path and strict account requirement
CREATE OR REPLACE FUNCTION public.fn_automate_adjustment_ledger_entry()
RETURNS TRIGGER AS $$
DECLARE
    v_account_id UUID;
    v_amount_owed_to_company NUMERIC(12,2);
    v_amount_owed_to_technician NUMERIC(12,2);
    v_net_balance NUMERIC(12,2);
    
    v_entry_type public.ledger_entry_type;
    v_debit NUMERIC(12,2) := 0.00;
    v_credit NUMERIC(12,2) := 0.00;
    v_running_balance NUMERIC(12,2);
    
    v_new_owed_to_company NUMERIC(12,2);
    v_new_owed_to_technician NUMERIC(12,2);
BEGIN
    -- Concurrency Guard: Lock the technician account for update
    SELECT id, amount_owed_to_company, amount_owed_to_technician, net_balance
    INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance
    FROM public.technician_financial_accounts
    WHERE technician_id = NEW.technician_id
    FOR UPDATE;

    -- Enforce strict architectural flow: raise error if account does not exist
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Technician financial account not found for ID %', NEW.technician_id USING ERRCODE = 'P0002';
    END IF;

    -- Map adjustment_type to ledger entry parameters
    IF NEW.adjustment_type = 'bonus' THEN
        v_entry_type := 'manual_bonus'::public.ledger_entry_type;
        v_credit := NEW.amount;
        v_debit := 0.00;
        v_new_owed_to_technician := v_amount_owed_to_technician + NEW.amount;
        v_new_owed_to_company := v_amount_owed_to_company;
        
    ELSIF NEW.adjustment_type = 'penalty' THEN
        v_entry_type := 'manual_penalty'::public.ledger_entry_type;
        v_debit := NEW.amount;
        v_credit := 0.00;
        v_new_owed_to_company := v_amount_owed_to_company + NEW.amount;
        v_new_owed_to_technician := v_amount_owed_to_technician;
        
    ELSIF NEW.adjustment_type = 'adjustment' THEN
        v_entry_type := 'manual_adjustment'::public.ledger_entry_type;
        
        -- Fallback: inspect the notes/reason text to check if it represents a debit
        IF LOWER(COALESCE(NEW.reason, '') || ' ' || COALESCE(NEW.notes, '')) LIKE '%debit%' THEN
            v_debit := NEW.amount;
            v_credit := 0.00;
            v_new_owed_to_company := v_amount_owed_to_company + NEW.amount;
            v_new_owed_to_technician := v_amount_owed_to_technician;
        ELSE
            v_credit := NEW.amount;
            v_debit := 0.00;
            v_new_owed_to_technician := v_amount_owed_to_technician + NEW.amount;
            v_new_owed_to_company := v_amount_owed_to_company;
        END IF;
    END IF;

    -- Calculate running balance
    v_running_balance := v_net_balance + v_credit - v_debit;

    -- Insert ledger entry
    INSERT INTO public.ledger_entries (
        account_id, adjustment_id, entry_type, debit, credit, running_balance, 
        description, reference_id, reference_type, created_by
    ) VALUES (
        v_account_id, NEW.id, v_entry_type, v_debit, v_credit, v_running_balance,
        NEW.reason, NEW.id, 'adjustment', NEW.approved_by
    );

    -- Update technician account
    UPDATE public.technician_financial_accounts
    SET 
        amount_owed_to_company = v_new_owed_to_company,
        amount_owed_to_technician = v_new_owed_to_technician,
        updated_at = NOW()
    WHERE id = v_account_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;

-- Recreate fn_automate_settlement_ledger_entry with secure search path and strict account requirement
CREATE OR REPLACE FUNCTION public.fn_automate_settlement_ledger_entry()
RETURNS TRIGGER AS $$
DECLARE
    v_account_id UUID;
    v_amount_owed_to_company NUMERIC(12,2);
    v_amount_owed_to_technician NUMERIC(12,2);
    v_net_balance NUMERIC(12,2);
    
    v_debit NUMERIC(12,2) := 0.00;
    v_credit NUMERIC(12,2) := 0.00;
    v_running_balance NUMERIC(12,2);
    
    v_new_owed_to_company NUMERIC(12,2);
    v_new_owed_to_technician NUMERIC(12,2);
BEGIN
    -- Concurrency Guard: Lock the technician account for update
    SELECT id, amount_owed_to_company, amount_owed_to_technician, net_balance
    INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance
    FROM public.technician_financial_accounts
    WHERE technician_id = NEW.technician_id
    FOR UPDATE;

    -- Enforce strict architectural flow: raise error if account does not exist
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Technician financial account not found for ID %', NEW.technician_id USING ERRCODE = 'P0002';
    END IF;

    -- Determine settlement direction based on NEW.request_type
    IF NEW.request_type = 'payment' THEN
        -- Paying Debt: reduces what they owe to the company
        v_credit := NEW.amount;
        v_debit := 0.00;
        
        -- Update balances: decrease debt
        v_new_owed_to_company := GREATEST(0.00, v_amount_owed_to_company - NEW.amount);
        v_new_owed_to_technician := v_amount_owed_to_technician;
        
        -- Rollover excess payment
        IF NEW.amount > v_amount_owed_to_company THEN
            v_new_owed_to_technician := v_amount_owed_to_technician + (NEW.amount - v_amount_owed_to_company);
        END IF;
    ELSE
        -- Withdrawing Earnings: reduces what the company owes to the technician
        v_debit := NEW.amount;
        v_credit := 0.00;
        
        -- Update balances: decrease credit
        v_new_owed_to_technician := GREATEST(0.00, v_amount_owed_to_technician - NEW.amount);
        v_new_owed_to_company := v_amount_owed_to_company;
        
        -- Rollover excess withdrawal
        IF NEW.amount > v_amount_owed_to_technician THEN
            v_new_owed_to_company := v_amount_owed_to_company + (NEW.amount - v_amount_owed_to_technician);
        END IF;
    END IF;

    -- Calculate running balance
    v_running_balance := v_net_balance + v_credit - v_debit;

    -- Insert ledger entry
    INSERT INTO public.ledger_entries (
        account_id, entry_type, debit, credit, running_balance, 
        description, reference_id, reference_type, created_by
    ) VALUES (
        v_account_id, 'settlement_reconciliation'::public.ledger_entry_type, v_debit, v_credit, v_running_balance,
        CASE 
            WHEN NEW.request_type = 'payment' THEN 'سداد مديونية للفني عبر ' || NEW.method::TEXT
            ELSE 'سحب مستحقات للفني عبر ' || NEW.method::TEXT
        END,
        NEW.id, 'settlement', NEW.reviewed_by
    );

    -- Update technician account
    UPDATE public.technician_financial_accounts
    SET 
        amount_owed_to_company = v_new_owed_to_company,
        amount_owed_to_technician = v_new_owed_to_technician,
        updated_at = NOW()
    WHERE id = v_account_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;


-- ── 3. FIX RISK 4: ZERO-VALUE CONSTRAINTS BYPASS GUARD ─────────────────────────

-- Recreate fn_automate_booking_ledger_entry with secure search path, strict account check, and Risk 4 guard clause
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

    -- FIX RISK 4: Bypass zero-value transactions (e.g. 100% discount free coupon codes)
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

    -- Handle cash payments vs online payments
    IF COALESCE(NEW.payment_method, 'cash') = 'cash' THEN
        -- Cash Orders
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
        -- Online Orders
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

-- Re-trigger status recalculation to ensure current states are updated
UPDATE public.technician_financial_accounts SET updated_at = NOW();

COMMIT;
