-- ==============================================================================
-- Fresh Home: Financial System Schema & Security Foundations (v1.0)
-- File: 06_financial_system.sql
-- Description: Creates enums, tables, constraints, ledger immutability, automated status
--              triggers, indexes, and Row Level Security (RLS) for the financial system.
-- ==============================================================================

BEGIN;

-- ── 1. ENUMS & CUSTOM TYPES ──────────────────────────────────────────────────

DO $$ BEGIN
    CREATE TYPE public.financial_account_status AS ENUM ('active', 'restricted', 'blocked');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.adjustment_type AS ENUM ('bonus', 'penalty', 'adjustment');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.adjustment_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.ledger_entry_type AS ENUM (
        'order_earnings', 
        'company_commission_debit', 
        'cash_collection_debit', 
        'manual_bonus', 
        'manual_penalty', 
        'manual_adjustment', 
        'settlement_reconciliation'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.settlement_method AS ENUM ('vodafone_cash', 'instapay', 'bank_transfer', 'cash_handover', 'other');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.settlement_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.financial_case_type AS ENUM (
        'refused_full_payment', 
        'partial_completion', 
        'admin_approved_discount', 
        'pricing_dispute', 
        'collection_discrepancy'
    );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE public.financial_case_status AS ENUM ('pending_review', 'in_investigation', 'resolved', 'dismissed');
EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ── 2. TABLES CREATION & CONSTRAINTS ─────────────────────────────────────────

-- Table A: public.technician_financial_accounts
CREATE TABLE IF NOT EXISTS public.technician_financial_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount_owed_to_company NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    amount_owed_to_technician NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    debt_limit NUMERIC(12,2) NOT NULL DEFAULT 1000.00,
    account_status public.financial_account_status NOT NULL DEFAULT 'active',
    
    -- Dynamic Balance (Generated Column Stored)
    net_balance NUMERIC(12,2) GENERATED ALWAYS AS (amount_owed_to_technician - amount_owed_to_company) STORED,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Constraints
    CONSTRAINT chk_amount_owed_to_company CHECK (amount_owed_to_company >= 0.00),
    CONSTRAINT chk_amount_owed_to_technician CHECK (amount_owed_to_technician >= 0.00),
    CONSTRAINT chk_debt_limit CHECK (debt_limit >= 0.00)
);

-- Table B: public.financial_adjustments
CREATE TABLE IF NOT EXISTS public.financial_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL,
    adjustment_type public.adjustment_type NOT NULL,
    reason TEXT NOT NULL,
    notes TEXT,
    attachment_url TEXT,
    status public.adjustment_status NOT NULL DEFAULT 'pending',
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT chk_adjustment_amount CHECK (amount > 0.00)
);

-- Table C: public.ledger_entries
CREATE TABLE IF NOT EXISTS public.ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES public.technician_financial_accounts(id) ON DELETE RESTRICT,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    adjustment_id UUID REFERENCES public.financial_adjustments(id) ON DELETE SET NULL,
    entry_type public.ledger_entry_type NOT NULL,
    debit NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    credit NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    running_balance NUMERIC(12,2) NOT NULL,
    description TEXT NOT NULL,
    
    -- Idempotency & Anti-Duplication tracking
    reference_id UUID NOT NULL,
    reference_type TEXT NOT NULL,
    
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Constraints
    CONSTRAINT chk_ledger_debit CHECK (debit >= 0.00),
    CONSTRAINT chk_ledger_credit CHECK (credit >= 0.00),
    CONSTRAINT chk_ledger_reference_type CHECK (reference_type IN ('booking', 'adjustment', 'settlement')),
    CONSTRAINT chk_ledger_values_xor CHECK (
        (debit > 0.00 AND credit = 0.00) OR 
        (credit > 0.00 AND debit = 0.00)
    ),
    CONSTRAINT uq_ledger_reference UNIQUE (reference_id, reference_type)
);

-- Table D: public.settlement_requests
CREATE TABLE IF NOT EXISTS public.settlement_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL,
    method public.settlement_method NOT NULL,
    proof_image_url TEXT NOT NULL,
    status public.settlement_status NOT NULL DEFAULT 'pending',
    admin_notes TEXT,
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Constraints
    CONSTRAINT chk_settlement_amount CHECK (amount > 0.00)
);

-- Table E: public.financial_cases
CREATE TABLE IF NOT EXISTS public.financial_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL UNIQUE REFERENCES public.bookings(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    discrepancy_type public.financial_case_type NOT NULL,
    expected_amount NUMERIC(12,2) NOT NULL,
    collected_amount NUMERIC(12,2) NOT NULL,
    description TEXT NOT NULL,
    status public.financial_case_status NOT NULL DEFAULT 'pending_review',
    resolution_notes TEXT,
    resolved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Constraints
    CONSTRAINT chk_case_expected CHECK (expected_amount >= 0.00),
    CONSTRAINT chk_case_collected CHECK (collected_amount >= 0.00)
);

-- Table F: public.financial_case_events
CREATE TABLE IF NOT EXISTS public.financial_case_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.financial_cases(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ── 3. FUNCTIONS & TRIGGERS (BUSINESS RULES & IMMUTABILITY) ──────────────────

-- A. Helper: Admin Verification Function (If not already created)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() 
          AND r.name = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- B. Immutability Enforcement Function for Ledger Entries
CREATE OR REPLACE FUNCTION public.fn_prevent_ledger_modifications()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Ledger entries are immutable. UPDATE and DELETE actions are strictly forbidden.'
        USING ERRCODE = '42000';
END;
$$ LANGUAGE plpgsql;

-- Attach Immutability Trigger
DROP TRIGGER IF EXISTS trg_prevent_ledger_modifications ON public.ledger_entries;
CREATE TRIGGER trg_prevent_ledger_modifications
BEFORE UPDATE OR DELETE ON public.ledger_entries
FOR EACH ROW
EXECUTE FUNCTION public.fn_prevent_ledger_modifications();

-- C. Automated Account Status Recalculation Engine
CREATE OR REPLACE FUNCTION public.fn_recalculate_account_status()
RETURNS TRIGGER AS $$
DECLARE
    v_ratio NUMERIC;
BEGIN
    IF NEW.debt_limit IS NULL OR NEW.debt_limit = 0.00 THEN
        NEW.account_status := 'active'::public.financial_account_status;
    ELSE
        v_ratio := NEW.amount_owed_to_company / NEW.debt_limit;
        
        IF v_ratio < 0.80 THEN
            NEW.account_status := 'active'::public.financial_account_status;
        ELSIF v_ratio >= 0.80 AND v_ratio < 1.00 THEN
            NEW.account_status := 'restricted'::public.financial_account_status;
        ELSE
            NEW.account_status := 'blocked'::public.financial_account_status;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach Status Trigger
DROP TRIGGER IF EXISTS trg_recalculate_account_status ON public.technician_financial_accounts;
CREATE TRIGGER trg_recalculate_account_status
BEFORE INSERT OR UPDATE OF amount_owed_to_company, debt_limit ON public.technician_financial_accounts
FOR EACH ROW
EXECUTE FUNCTION public.fn_recalculate_account_status();

-- D. Shared handle_updated_at helper
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach updated_at Triggers
DROP TRIGGER IF EXISTS trg_financial_accounts_updated_at ON public.technician_financial_accounts;
CREATE TRIGGER trg_financial_accounts_updated_at BEFORE UPDATE ON public.technician_financial_accounts FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_financial_adjustments_updated_at ON public.financial_adjustments;
CREATE TRIGGER trg_financial_adjustments_updated_at BEFORE UPDATE ON public.financial_adjustments FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_settlement_requests_updated_at ON public.settlement_requests;
CREATE TRIGGER trg_settlement_requests_updated_at BEFORE UPDATE ON public.settlement_requests FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_financial_cases_updated_at ON public.financial_cases;
CREATE TRIGGER trg_financial_cases_updated_at BEFORE UPDATE ON public.financial_cases FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ── 4. INDEXES & RLS SECURITY POLICIES ────────────────────────────────────────

-- Indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_financial_accounts_tech_id ON public.technician_financial_accounts(technician_id);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_lookup ON public.ledger_entries(account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_booking_id ON public.ledger_entries(booking_id);
CREATE INDEX IF NOT EXISTS idx_financial_adjustments_tech_status ON public.financial_adjustments(technician_id, status);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_tech_status ON public.settlement_requests(technician_id, status);
CREATE INDEX IF NOT EXISTS idx_financial_cases_booking_id ON public.financial_cases(booking_id);
CREATE INDEX IF NOT EXISTS idx_financial_case_events_case_id ON public.financial_case_events(case_id);

-- Enable RLS
ALTER TABLE public.technician_financial_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlement_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_case_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Accounts Policies
DROP POLICY IF EXISTS admin_all_accounts ON public.technician_financial_accounts;
CREATE POLICY admin_all_accounts ON public.technician_financial_accounts
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS tech_select_own_account ON public.technician_financial_accounts;
CREATE POLICY tech_select_own_account ON public.technician_financial_accounts
    FOR SELECT TO authenticated USING (technician_id = auth.uid());

-- Adjustments Policies
DROP POLICY IF EXISTS admin_all_adjustments ON public.financial_adjustments;
CREATE POLICY admin_all_adjustments ON public.financial_adjustments
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS tech_select_own_adjustments ON public.financial_adjustments;
CREATE POLICY tech_select_own_adjustments ON public.financial_adjustments
    FOR SELECT TO authenticated USING (technician_id = auth.uid());

-- Ledger Policies
DROP POLICY IF EXISTS admin_all_ledger ON public.ledger_entries;
CREATE POLICY admin_all_ledger ON public.ledger_entries
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS tech_select_own_ledger ON public.ledger_entries;
CREATE POLICY tech_select_own_ledger ON public.ledger_entries
    FOR SELECT TO authenticated USING (
        account_id IN (
            SELECT id FROM public.technician_financial_accounts 
            WHERE technician_id = auth.uid()
        )
    );

-- Settlements Policies
DROP POLICY IF EXISTS admin_all_settlements ON public.settlement_requests;
CREATE POLICY admin_all_settlements ON public.settlement_requests
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS tech_select_own_settlements ON public.settlement_requests;
CREATE POLICY tech_select_own_settlements ON public.settlement_requests
    FOR SELECT TO authenticated USING (technician_id = auth.uid());

DROP POLICY IF EXISTS tech_insert_own_settlements ON public.settlement_requests;
CREATE POLICY tech_insert_own_settlements ON public.settlement_requests
    FOR INSERT TO authenticated WITH CHECK (
        technician_id = auth.uid() 
        AND status = 'pending'::public.settlement_status
    );

-- Cases Policies
DROP POLICY IF EXISTS admin_all_cases ON public.financial_cases;
CREATE POLICY admin_all_cases ON public.financial_cases
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS tech_select_own_cases ON public.financial_cases;
CREATE POLICY tech_select_own_cases ON public.financial_cases
    FOR SELECT TO authenticated USING (
        booking_id IN (
            SELECT id FROM public.bookings 
            WHERE technician_id = auth.uid()
        )
    );

-- Case Events Policies
DROP POLICY IF EXISTS admin_all_case_events ON public.financial_case_events;
CREATE POLICY admin_all_case_events ON public.financial_case_events
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS tech_select_own_case_events ON public.financial_case_events;
CREATE POLICY tech_select_own_case_events ON public.financial_case_events
    FOR SELECT TO authenticated USING (
        case_id IN (
            SELECT fc.id FROM public.financial_cases fc
            JOIN public.bookings b ON fc.booking_id = b.id
            WHERE b.technician_id = auth.uid()
        )
    );

COMMIT;
