-- Migration ID: 67_add_settlement_request_type_and_make_proof_nullable
-- Description: Make proof_image_url nullable, add request_type column, update status and settlement triggers.

BEGIN;

-- 1. Make proof_image_url nullable in settlement_requests
ALTER TABLE public.settlement_requests ALTER COLUMN proof_image_url DROP NOT NULL;

-- 2. Add request_type column to settlement_requests
ALTER TABLE public.settlement_requests 
ADD COLUMN request_type TEXT NOT NULL DEFAULT 'withdrawal' 
CONSTRAINT chk_settlement_request_type CHECK (request_type IN ('withdrawal', 'payment'));

-- 3. Update the settlement reconciliation trigger function
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

    -- Proactive account registration if missing
    IF NOT FOUND THEN
        INSERT INTO public.technician_financial_accounts (technician_id)
        VALUES (NEW.technician_id)
        RETURNING id, amount_owed_to_company, amount_owed_to_technician, net_balance
        INTO v_account_id, v_amount_owed_to_company, v_amount_owed_to_technician, v_net_balance;
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
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 4. Update the account status recalculation function
CREATE OR REPLACE FUNCTION public.fn_recalculate_account_status()
RETURNS TRIGGER AS $$
DECLARE
    v_ratio NUMERIC;
    v_net_debt NUMERIC;
BEGIN
    IF NEW.debt_limit IS NULL OR NEW.debt_limit = 0.00 THEN
        NEW.account_status := 'active'::public.financial_account_status;
    ELSE
        -- Net debt is gross company debt minus gross technician credit
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
$$ LANGUAGE plpgsql;

-- 5. Re-create status trigger to run on updates of company debt, tech credit, or debt limit
DROP TRIGGER IF EXISTS trg_recalculate_account_status ON public.technician_financial_accounts;
CREATE TRIGGER trg_recalculate_account_status
BEFORE INSERT OR UPDATE OF amount_owed_to_company, amount_owed_to_technician, debt_limit ON public.technician_financial_accounts
FOR EACH ROW
EXECUTE FUNCTION public.fn_recalculate_account_status();

-- 6. Trigger update on all existing accounts to refresh statuses under the new logic
UPDATE public.technician_financial_accounts SET updated_at = NOW();

COMMIT;
