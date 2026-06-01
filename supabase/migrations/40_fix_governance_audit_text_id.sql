-- ==============================================================================
-- Fresh Home: Fix pricing_governance_audit & trigger for TEXT service IDs
-- Migration ID: 40_fix_governance_audit_text_id
-- 
-- Problem:
--   Migration 34_services_readable_id.sql converted services.id and all related
--   FK columns (pricing_rules, pricing_discounts, pricing_versions) from UUID to
--   TEXT to support readable IDs like "FH-S-100014". However it missed:
--     1. pricing_governance_audit.sub_service_id  (still UUID)
--     2. fn_audit_pricing_changes() DECLARE block  (v_sub_service_id UUID)
--
--   When a Flutter admin navigates to the Pricing Governance Dashboard and passes
--   a readable service ID, Supabase throws:
--     PostgrestException: invalid input syntax for type uuid: "FH-S-100014"
--
-- Fix:
--   A. Alter pricing_governance_audit.sub_service_id from UUID → TEXT
--   B. Also convert rule_id and discount_id to TEXT for FK compatibility
--   C. Recreate fn_audit_pricing_changes() with TEXT variable types
-- ==============================================================================

BEGIN;

-- ── Step A: Fix pricing_governance_audit column types ─────────────────────────

-- Drop any FK constraints that reference uuid-typed columns first
-- (the table has no FK constraints declared by default but drop if any exist)
ALTER TABLE public.pricing_governance_audit
    DROP CONSTRAINT IF EXISTS pricing_governance_audit_sub_service_id_fkey;

ALTER TABLE public.pricing_governance_audit
    DROP CONSTRAINT IF EXISTS pricing_governance_audit_rule_id_fkey;

ALTER TABLE public.pricing_governance_audit
    DROP CONSTRAINT IF EXISTS pricing_governance_audit_discount_id_fkey;

-- Convert sub_service_id from UUID → TEXT (holds readable IDs like "FH-S-100014")
ALTER TABLE public.pricing_governance_audit
    ALTER COLUMN sub_service_id TYPE TEXT USING sub_service_id::TEXT;

-- Convert rule_id from UUID → TEXT (pricing_rules.id may also become readable)
ALTER TABLE public.pricing_governance_audit
    ALTER COLUMN rule_id TYPE TEXT USING rule_id::TEXT;

-- Convert discount_id from UUID → TEXT (pricing_discounts.id may also become readable)
ALTER TABLE public.pricing_governance_audit
    ALTER COLUMN discount_id TYPE TEXT USING discount_id::TEXT;

-- ── Step B: Recreate fn_audit_pricing_changes() with TEXT variable types ──────

CREATE OR REPLACE FUNCTION public.fn_audit_pricing_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_action         TEXT;
    v_before         JSONB := NULL;
    v_after          JSONB := NULL;
    v_sub_service_id TEXT := NULL;   -- ✅ Was UUID — now TEXT for readable IDs
    v_rule_id        TEXT := NULL;   -- ✅ Was UUID — now TEXT
    v_discount_id    TEXT := NULL;   -- ✅ Was UUID — now TEXT
BEGIN
    v_action := TG_OP;

    IF TG_TABLE_NAME = 'pricing_rules' THEN
        IF v_action = 'INSERT' THEN
            v_after          := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id::TEXT;
            v_rule_id        := NEW.id::TEXT;
        ELSIF v_action = 'UPDATE' THEN
            v_before         := to_jsonb(OLD);
            v_after          := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id::TEXT;
            v_rule_id        := NEW.id::TEXT;
        ELSIF v_action = 'DELETE' THEN
            v_before         := to_jsonb(OLD);
            v_sub_service_id := OLD.sub_service_id::TEXT;
            v_rule_id        := OLD.id::TEXT;
        END IF;

    ELSIF TG_TABLE_NAME = 'pricing_discounts' THEN
        IF v_action = 'INSERT' THEN
            v_after          := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id::TEXT;
            v_discount_id    := NEW.id::TEXT;
        ELSIF v_action = 'UPDATE' THEN
            v_before         := to_jsonb(OLD);
            v_after          := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id::TEXT;
            v_discount_id    := NEW.id::TEXT;
        ELSIF v_action = 'DELETE' THEN
            v_before         := to_jsonb(OLD);
            v_sub_service_id := OLD.sub_service_id::TEXT;
            v_discount_id    := OLD.id::TEXT;
        END IF;
    END IF;

    INSERT INTO public.pricing_governance_audit (
        sub_service_id, rule_id, discount_id, action, actor_id, before_state, after_state
    ) VALUES (
        v_sub_service_id,
        v_rule_id,
        v_discount_id,
        v_action,
        auth.uid(),
        v_before,
        v_after
    );

    IF v_action = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Step C: Re-attach triggers (no-op if already attached, ensures idempotency) ─

DROP TRIGGER IF EXISTS trg_audit_pricing_rules ON public.pricing_rules;
CREATE TRIGGER trg_audit_pricing_rules
AFTER INSERT OR UPDATE OR DELETE ON public.pricing_rules
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_pricing_changes();

DROP TRIGGER IF EXISTS trg_audit_pricing_discounts ON public.pricing_discounts;
CREATE TRIGGER trg_audit_pricing_discounts
AFTER INSERT OR UPDATE OR DELETE ON public.pricing_discounts
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_pricing_changes();

COMMIT;
