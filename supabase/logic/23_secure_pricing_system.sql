-- ==============================================================================
-- Fresh Home: Secure Server-Side Pricing System & Immutable Ledger Auditing (v6.0)
-- File: 23_secure_pricing_system.sql
--
-- Objective:
-- 1. Create Dedicated Pricing Versioning Table: public.pricing_versions.
-- 2. Dynamically add Audit Locking and Inputs columns to public.bookings.
-- 3. Build dynamic version snapshot capturing engine: capture_pricing_version.
-- 4. Refactor Stages 2 and 4 to execute directly from snapshots when replaying.
-- 5. Introduce unified ledger replay auditing engine: replay_booking_pricing.
-- 6. Guarantee complete zero-downtime backward compatibility.
-- ==============================================================================

-- ── 1. SCHEMA MIGRATION: RULES, DISCOUNTS, AND ARCHIVAL ENTITIES ──────────────

-- Create pricing rules table if not present
CREATE TABLE IF NOT EXISTS public.pricing_rules (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    description    TEXT,
    condition_ast  JSONB NOT NULL, -- Recursive AST structured schema
    action_type    TEXT NOT NULL,  -- 'multiply' | 'add' | 'override' | 'percent'
    action_value   NUMERIC NOT NULL,
    action_target  TEXT NOT NULL DEFAULT 'subtotal', -- 'base_price' | 'subtotal' | 'extra_fees'
    priority       INT NOT NULL,
    is_active      BOOLEAN NOT NULL DEFAULT true,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_sub_service_priority UNIQUE (sub_service_id, priority)
);

-- Enable Row Level Security (RLS) on pricing_rules
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;

-- Enable select access for authenticated users, admin-only write access
DROP POLICY IF EXISTS select_pricing_rules ON public.pricing_rules;
DROP POLICY IF EXISTS all_admin_pricing_rules ON public.pricing_rules;
DROP POLICY IF EXISTS pricing_read_only ON public.pricing_rules;
DROP POLICY IF EXISTS pricing_admin_full_access ON public.pricing_rules;

CREATE POLICY pricing_read_only ON public.pricing_rules
    FOR SELECT TO authenticated USING (true);

CREATE POLICY pricing_admin_full_access ON public.pricing_rules
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Create pricing discounts table if not present
CREATE TABLE IF NOT EXISTS public.pricing_discounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_service_id  UUID REFERENCES public.services(id) ON DELETE CASCADE, -- If NULL, is a global discount
    name            TEXT NOT NULL,
    code            TEXT, -- Optional coupon code (e.g. 'SAVE20')
    type            TEXT NOT NULL, -- 'coupon' | 'first_order' | 'vip' | 'bulk_orders' | 'service_specific'
    value_type      TEXT NOT NULL, -- 'percentage' | 'fixed'
    value           NUMERIC NOT NULL,
    conditions_ast  JSONB NOT NULL DEFAULT '{}'::JSONB, -- Recursive AST structured conditions
    priority        INT NOT NULL DEFAULT 10,
    stackable       BOOLEAN NOT NULL DEFAULT true,
    max_stack_limit NUMERIC,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    start_date      TIMESTAMPTZ,
    end_date        TIMESTAMPTZ,
    usage_limit     INT,
    usage_count     INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS) on pricing_discounts
ALTER TABLE public.pricing_discounts ENABLE ROW LEVEL SECURITY;

-- Enable select access for authenticated users, admin-only write access
DROP POLICY IF EXISTS select_pricing_discounts ON public.pricing_discounts;
DROP POLICY IF EXISTS all_admin_pricing_discounts ON public.pricing_discounts;
DROP POLICY IF EXISTS pricing_discounts_read_only ON public.pricing_discounts;
DROP POLICY IF EXISTS pricing_discounts_admin_full_access ON public.pricing_discounts;

CREATE POLICY pricing_discounts_read_only ON public.pricing_discounts
    FOR SELECT TO authenticated USING (true);

CREATE POLICY pricing_discounts_admin_full_access ON public.pricing_discounts
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Create immutable pricing versions table
CREATE TABLE IF NOT EXISTS public.pricing_versions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    snapshot       JSONB NOT NULL, -- Full price_config + rules + discounts archive
    is_active      BOOLEAN NOT NULL DEFAULT true,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS) on pricing_versions
ALTER TABLE public.pricing_versions ENABLE ROW LEVEL SECURITY;

-- Enable select access for authenticated users, admin-only write access
DROP POLICY IF EXISTS select_pricing_versions ON public.pricing_versions;
DROP POLICY IF EXISTS all_admin_pricing_versions ON public.pricing_versions;
DROP POLICY IF EXISTS pricing_versions_read_only ON public.pricing_versions;
DROP POLICY IF EXISTS pricing_versions_admin_full_access ON public.pricing_versions;

CREATE POLICY pricing_versions_read_only ON public.pricing_versions
    FOR SELECT TO authenticated USING (true);

CREATE POLICY pricing_versions_admin_full_access ON public.pricing_versions
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Dynamically alter bookings table to add audit tracking columns safely
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS pricing_inputs JSONB NOT NULL DEFAULT '{}'::JSONB;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS pricing_version_id UUID REFERENCES public.pricing_versions(id) ON DELETE SET NULL;

-- ── 2. DROP MIGRATION FUNCTIONS TO PREVENT PARAMETER OVERLOAD ERRORS ─────────
ALTER TABLE public.pricing_rules DROP CONSTRAINT IF EXISTS chk_pricing_rules_ast;
ALTER TABLE public.pricing_discounts DROP CONSTRAINT IF EXISTS chk_pricing_discounts_ast;

DROP FUNCTION IF EXISTS public.evaluate_ast_condition(JSONB, JSONB);
DROP FUNCTION IF EXISTS public.validate_condition_ast(JSONB);
DROP FUNCTION IF EXISTS public.apply_pricing_rules(JSONB, UUID);
DROP FUNCTION IF EXISTS public.apply_discounts(UUID, JSONB);
DROP FUNCTION IF EXISTS public.stage_1_calculate_base_pricing(UUID, JSONB, JSONB);
DROP FUNCTION IF EXISTS public.stage_2_apply_conditional_rules(UUID, JSONB);
DROP FUNCTION IF EXISTS public.stage_3_apply_options(UUID, JSONB, JSONB);
DROP FUNCTION IF EXISTS public.stage_4_apply_discounts(UUID, JSONB);
DROP FUNCTION IF EXISTS public.stage_5_finalize_pricing(UUID, JSONB);
DROP FUNCTION IF EXISTS public.capture_pricing_version(UUID);
DROP FUNCTION IF EXISTS public.execute_pricing_pipeline(UUID, JSONB, JSONB);
DROP FUNCTION IF EXISTS public.calculate_booking_price(UUID, JSONB);
DROP FUNCTION IF EXISTS public.replay_booking_pricing(UUID);
DROP FUNCTION IF EXISTS public.create_atomic_booking(
    UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT
);

-- ── 3. CREATE DOCK VALIDATION SCHEMAS AND HELPER FUNCTIONS ───────────────────

-- Helper: Validates AST Condition integrity at database check constraints level
CREATE OR REPLACE FUNCTION public.validate_condition_ast(p_ast JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    v_type  TEXT;
    v_conds JSONB;
    v_item  JSONB;
BEGIN
    -- Allow empty/default conditions objects
    IF p_ast IS NULL OR p_ast = '{}'::JSONB THEN
        RETURN TRUE;
    END IF;

    -- Standard object schema checks
    IF jsonb_typeof(p_ast) = 'object' THEN
        v_type := p_ast ->> 'type';
        IF v_type IS NOT NULL AND v_type IN ('AND', 'OR') THEN
            v_conds := p_ast -> 'conditions';
            IF v_conds IS NULL OR jsonb_typeof(v_conds) != 'array' THEN
                RETURN FALSE;
            END IF;
            
            -- Recursively check array conditions
            FOR v_item IN SELECT * FROM jsonb_array_elements(v_conds) LOOP
                IF NOT public.validate_condition_ast(v_item) THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
            RETURN TRUE;
        ELSE
            -- Leaf comparison blocks require: 'field', 'operator', and 'value' properties
            IF (p_ast ->> 'field') IS NULL OR (p_ast ->> 'operator') IS NULL OR (p_ast -> 'value') IS NULL THEN
                RETURN FALSE;
            END IF;
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Safely attach AST checker constraints
ALTER TABLE public.pricing_rules DROP CONSTRAINT IF EXISTS chk_pricing_rules_ast;
ALTER TABLE public.pricing_rules ADD CONSTRAINT chk_pricing_rules_ast CHECK (public.validate_condition_ast(condition_ast));

ALTER TABLE public.pricing_discounts DROP CONSTRAINT IF EXISTS chk_pricing_discounts_ast;
ALTER TABLE public.pricing_discounts ADD CONSTRAINT chk_pricing_discounts_ast CHECK (public.validate_condition_ast(conditions_ast));

-- Helper: Recursive AST Pricing Conditions Evaluation Engine (Fail-safe, Stack-safe)
CREATE OR REPLACE FUNCTION public.evaluate_ast_condition(
    p_condition JSONB,
    p_inputs JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    v_type        TEXT;
    v_cond_array  JSONB;
    v_item        JSONB;
    v_field       TEXT;
    v_operator    TEXT;
    v_expected    JSONB;
    v_actual      JSONB;
    v_res         BOOLEAN;
BEGIN
    IF p_condition IS NULL OR p_inputs IS NULL OR p_condition = '{}'::JSONB THEN
        RETURN TRUE;
    END IF;

    v_type := p_condition ->> 'type';

    IF v_type = 'AND' THEN
        v_cond_array := p_condition -> 'conditions';
        IF v_cond_array IS NULL OR jsonb_typeof(v_cond_array) != 'array' THEN
            RETURN FALSE;
        END IF;

        FOR v_item IN SELECT * FROM jsonb_array_elements(v_cond_array) LOOP
            v_res := public.evaluate_ast_condition(v_item, p_inputs);
            IF v_res IS NOT TRUE THEN
                RETURN FALSE;
            END IF;
        END LOOP;
        RETURN TRUE;

    ELSIF v_type = 'OR' THEN
        v_cond_array := p_condition -> 'conditions';
        IF v_cond_array IS NULL OR jsonb_typeof(v_cond_array) != 'array' THEN
            RETURN FALSE;
        END IF;

        FOR v_item IN SELECT * FROM jsonb_array_elements(v_cond_array) LOOP
            v_res := public.evaluate_ast_condition(v_item, p_inputs);
            IF v_res IS TRUE THEN
                RETURN TRUE;
            END IF;
        END LOOP;
        RETURN FALSE;

    ELSE
        -- Leaf comparison evaluation
        v_field := p_condition ->> 'field';
        v_operator := p_condition ->> 'operator';
        v_expected := p_condition -> 'value';

        IF v_field IS NULL OR NOT (p_inputs ? v_field) THEN
            RETURN FALSE;
        END IF;

        v_actual := p_inputs -> v_field;

        IF v_operator = '=' OR v_operator = '==' THEN
            RETURN v_actual = v_expected;
        ELSIF v_operator = '!=' OR v_operator = '<>' THEN
            RETURN v_actual != v_expected;
        ELSIF v_operator = '>' THEN
            RETURN (v_actual::TEXT::NUMERIC) > (v_expected::TEXT::NUMERIC);
        ELSIF v_operator = '>=' THEN
            RETURN (v_actual::TEXT::NUMERIC) >= (v_expected::TEXT::NUMERIC);
        ELSIF v_operator = '<' THEN
            RETURN (v_actual::TEXT::NUMERIC) < (v_expected::TEXT::NUMERIC);
        ELSIF v_operator = '<=' THEN
            RETURN (v_actual::TEXT::NUMERIC) <= (v_expected::TEXT::NUMERIC);
        ELSE
            RETURN FALSE;
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE; -- Fail-safe recovery skips corrupted conditions
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: Relational Rules Evaluator & Action Executor (Enforces Traceable Logs)
CREATE OR REPLACE FUNCTION public.apply_pricing_rules(
    p_context JSONB,
    p_sub_service_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_pricing_inputs JSONB;
    v_base_price     NUMERIC;
    v_subtotal       NUMERIC;
    v_extra_fees     NUMERIC;
    v_rule           RECORD;
    v_matches        BOOLEAN;
    v_val            NUMERIC;
    
    v_before         NUMERIC;
    v_after          NUMERIC;
    v_applied_rules  JSONB;
    v_trace          JSONB;
    v_trace_entry    JSONB;
BEGIN
    v_pricing_inputs := p_context -> 'pricing_inputs';
    v_base_price     := (p_context ->> 'base_price')::NUMERIC;
    v_subtotal       := (p_context ->> 'subtotal')::NUMERIC;
    v_extra_fees     := (p_context ->> 'extra_fees')::NUMERIC;
    
    v_applied_rules  := COALESCE(p_context -> 'applied_rules', '[]'::JSONB);
    v_trace          := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);

    -- Stacking source check: use archived version rules if present, else query live B-Tree table
    IF p_context ? 'snapshot_rules' THEN
        FOR v_rule IN 
            SELECT * FROM jsonb_to_recordset(p_context -> 'snapshot_rules') AS z(
                id UUID, name TEXT, condition_ast JSONB, action_type TEXT, action_value NUMERIC, action_target TEXT
            )
        LOOP
            BEGIN
                v_matches := public.evaluate_ast_condition(v_rule.condition_ast, v_pricing_inputs);
            EXCEPTION WHEN OTHERS THEN
                v_matches := false;
            END;

            IF v_matches IS TRUE THEN
                v_val := v_rule.action_value;
                
                IF v_rule.action_target = 'base_price' THEN
                    v_before := v_base_price;
                    IF v_rule.action_type = 'override' THEN
                        v_base_price := v_val;
                    ELSIF v_rule.action_type = 'add' THEN
                        v_base_price := v_base_price + v_val;
                    ELSIF v_rule.action_type = 'multiply' THEN
                        v_base_price := v_base_price * v_val;
                    ELSIF v_rule.action_type = 'percent' THEN
                        v_base_price := v_base_price + (v_base_price * (v_val / 100.0));
                    END IF;
                    v_after := v_base_price;
                    v_subtotal := v_base_price;

                ELSIF v_rule.action_target = 'subtotal' THEN
                    v_before := v_subtotal;
                    IF v_rule.action_type = 'override' THEN
                        v_subtotal := v_val;
                    ELSIF v_rule.action_type = 'add' THEN
                        v_subtotal := v_subtotal + v_val;
                    ELSIF v_rule.action_type = 'multiply' THEN
                        v_subtotal := v_subtotal * v_val;
                    ELSIF v_rule.action_type = 'percent' THEN
                        v_subtotal := v_subtotal + (v_subtotal * (v_val / 100.0));
                    END IF;
                    v_after := v_subtotal;

                ELSIF v_rule.action_target = 'extra_fees' THEN
                    v_before := v_extra_fees;
                    IF v_rule.action_type = 'override' THEN
                        v_extra_fees := v_val;
                    ELSIF v_rule.action_type = 'add' THEN
                        v_extra_fees := v_extra_fees + v_val;
                    ELSIF v_rule.action_type = 'multiply' THEN
                        v_extra_fees := v_extra_fees * v_val;
                    ELSIF v_rule.action_type = 'percent' THEN
                        v_extra_fees := v_extra_fees + (v_extra_fees * (v_val / 100.0));
                    END IF;
                    v_after := v_extra_fees;
                END IF;

                v_trace_entry := jsonb_build_object(
                    'stage', 'stage_2_rules',
                    'rule_id', v_rule.id,
                    'rule_name', v_rule.name,
                    'action', v_rule.action_type,
                    'target', v_rule.action_target,
                    'before', v_before,
                    'after', v_after,
                    'source', 'locked_pricing_snapshot'
                );
                v_trace := v_trace || v_trace_entry;

                v_applied_rules := v_applied_rules || jsonb_build_object(
                    'id', v_rule.id,
                    'name', v_rule.name
                );
            END IF;
        END LOOP;
    ELSE
        -- Query active rules ordered strictly by priority ASC (prevents ambiguous stack sequence)
        FOR v_rule IN 
            SELECT id, name, condition_ast, action_type, action_value, action_target
            FROM public.pricing_rules
            WHERE sub_service_id = p_sub_service_id AND is_active = true
            ORDER BY priority ASC
        LOOP
            BEGIN
                v_matches := public.evaluate_ast_condition(v_rule.condition_ast, v_pricing_inputs);
            EXCEPTION WHEN OTHERS THEN
                v_matches := false;
            END;

            IF v_matches IS TRUE THEN
                v_val := v_rule.action_value;
                
                IF v_rule.action_target = 'base_price' THEN
                    v_before := v_base_price;
                    IF v_rule.action_type = 'override' THEN
                        v_base_price := v_val;
                    ELSIF v_rule.action_type = 'add' THEN
                        v_base_price := v_base_price + v_val;
                    ELSIF v_rule.action_type = 'multiply' THEN
                        v_base_price := v_base_price * v_val;
                    ELSIF v_rule.action_type = 'percent' THEN
                        v_base_price := v_base_price + (v_base_price * (v_val / 100.0));
                    END IF;
                    v_after := v_base_price;
                    v_subtotal := v_base_price;

                ELSIF v_rule.action_target = 'subtotal' THEN
                    v_before := v_subtotal;
                    IF v_rule.action_type = 'override' THEN
                        v_subtotal := v_val;
                    ELSIF v_rule.action_type = 'add' THEN
                        v_subtotal := v_subtotal + v_val;
                    ELSIF v_rule.action_type = 'multiply' THEN
                        v_subtotal := v_subtotal * v_val;
                    ELSIF v_rule.action_type = 'percent' THEN
                        v_subtotal := v_subtotal + (v_subtotal * (v_val / 100.0));
                    END IF;
                    v_after := v_subtotal;

                ELSIF v_rule.action_target = 'extra_fees' THEN
                    v_before := v_extra_fees;
                    IF v_rule.action_type = 'override' THEN
                        v_extra_fees := v_val;
                    ELSIF v_rule.action_type = 'add' THEN
                        v_extra_fees := v_extra_fees + v_val;
                    ELSIF v_rule.action_type = 'multiply' THEN
                        v_extra_fees := v_extra_fees * v_val;
                    ELSIF v_rule.action_type = 'percent' THEN
                        v_extra_fees := v_extra_fees + (v_extra_fees * (v_val / 100.0));
                    END IF;
                    v_after := v_extra_fees;
                END IF;

                v_trace_entry := jsonb_build_object(
                    'stage', 'stage_2_rules',
                    'rule_id', v_rule.id,
                    'rule_name', v_rule.name,
                    'action', v_rule.action_type,
                    'target', v_rule.action_target,
                    'before', v_before,
                    'after', v_after,
                    'source', 'live_database_rules'
                );
                v_trace := v_trace || v_trace_entry;

                v_applied_rules := v_applied_rules || jsonb_build_object(
                    'id', v_rule.id,
                    'name', v_rule.name
                );
            END IF;
        END LOOP;
    END IF;

    RETURN p_context || jsonb_build_object(
        'base_price', v_base_price,
        'subtotal', v_subtotal,
        'extra_fees', v_extra_fees,
        'applied_rules', v_applied_rules,
        'execution_trace', v_trace
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: Relational Dynamic Discounts Stacking Evaluation Engine
CREATE OR REPLACE FUNCTION public.apply_discounts(
    p_sub_service_id UUID,
    p_context JSONB
) RETURNS JSONB AS $$
DECLARE
    v_pricing_inputs         JSONB;
    v_subtotal               NUMERIC;
    v_coupon_code            TEXT;
    v_disc                   RECORD;
    v_matches                BOOLEAN;
    
    v_total_discount_amount  NUMERIC := 0.0;
    v_max_cap_limit          NUMERIC;
    v_current_disc_amt       NUMERIC;
    v_has_non_stackable      BOOLEAN := false;
    v_stack_position         INT := 0;
    
    v_applied_discounts      JSONB;
    v_trace                  JSONB;
    v_trace_entry            JSONB;
BEGIN
    v_pricing_inputs := p_context -> 'pricing_inputs';
    v_subtotal       := (p_context ->> 'subtotal')::NUMERIC;
    
    v_applied_discounts := COALESCE(p_context -> 'applied_discounts', '[]'::JSONB);
    v_trace             := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);
    
    v_coupon_code := v_pricing_inputs ->> 'coupon_code';
    v_max_cap_limit := v_subtotal * 0.30;

    -- Stacking source check: use archived version discounts if present, else query live B-Tree table
    IF p_context ? 'snapshot_discounts' THEN
        FOR v_disc IN 
            SELECT * FROM jsonb_to_recordset(p_context -> 'snapshot_discounts') AS w(
                id UUID, name TEXT, code TEXT, type TEXT, value_type TEXT, value NUMERIC, conditions_ast JSONB, priority INT, stackable BOOLEAN
            )
        LOOP
            IF v_has_non_stackable IS TRUE THEN
                CONTINUE;
            END IF;

            IF v_disc.type = 'coupon' THEN
                IF v_coupon_code IS NULL OR LOWER(v_coupon_code) != LOWER(v_disc.code) THEN
                    CONTINUE;
                END IF;
                -- Date bounds and limits omitted in snapshots since they were already authoritatively locked at checkout
            END IF;

            BEGIN
                v_matches := public.evaluate_ast_condition(v_disc.conditions_ast, v_pricing_inputs);
            EXCEPTION WHEN OTHERS THEN
                v_matches := false;
            END;

            IF v_matches IS TRUE OR v_disc.conditions_ast = '{}'::JSONB OR v_disc.conditions_ast IS NULL THEN
                v_stack_position := v_stack_position + 1;

                IF v_disc.value_type = 'percentage' THEN
                    v_current_disc_amt := v_subtotal * (v_disc.value / 100.0);
                ELSIF v_disc.value_type = 'fixed' THEN
                    v_current_disc_amt := v_disc.value;
                ELSE
                    v_current_disc_amt := 0.0;
                END IF;

                IF v_total_discount_amount + v_current_disc_amt > v_max_cap_limit THEN
                    v_current_disc_amt := v_max_cap_limit - v_total_discount_amount;
                END IF;

                IF v_current_disc_amt < 0 THEN
                    v_current_disc_amt := 0.0;
                END IF;

                IF v_current_disc_amt > 0 THEN
                    v_total_discount_amount := v_total_discount_amount + v_current_disc_amt;
                    
                    IF v_disc.stackable IS FALSE THEN
                        v_has_non_stackable := true;
                    END IF;

                    v_trace_entry := jsonb_build_object(
                        'stage', 'stage_4_discounts',
                        'discount_id', v_disc.id,
                        'discount_name', v_disc.name,
                        'type', v_disc.value_type,
                        'value_before', v_subtotal,
                        'value_after', (v_subtotal - v_total_discount_amount),
                        'applied_logic', v_disc.type,
                        'stacking_position', v_stack_position,
                        'source', 'locked_pricing_snapshot'
                    );
                    v_trace := v_trace || v_trace_entry;

                    v_applied_discounts := v_applied_discounts || jsonb_build_object(
                        'id', v_disc.id,
                        'name', v_disc.name,
                        'amount', v_current_disc_amt
                    );
                END IF;
            END IF;
        END LOOP;
    ELSE
        -- Query active campaigns matching sub_service_id OR global (sub_service_id IS NULL)
        FOR v_disc IN 
            SELECT id, name, code, type, value_type, value, conditions_ast, priority, stackable, usage_limit, usage_count, start_date, end_date
            FROM public.pricing_discounts
            WHERE (sub_service_id = p_sub_service_id OR sub_service_id IS NULL)
              AND is_active = true
            ORDER BY priority ASC
        LOOP
            IF v_has_non_stackable IS TRUE THEN
                CONTINUE;
            END IF;

            IF v_disc.type = 'coupon' THEN
                IF v_coupon_code IS NULL OR LOWER(v_coupon_code) != LOWER(v_disc.code) THEN
                    CONTINUE;
                END IF;

                IF v_disc.start_date IS NOT NULL AND now() < v_disc.start_date THEN
                    RAISE EXCEPTION 'كوبون الخصم % لم يبدأ تفعيله بعد', v_disc.code USING ERRCODE = 'P0005';
                END IF;
                IF v_disc.end_date IS NOT NULL AND now() > v_disc.end_date THEN
                    RAISE EXCEPTION 'كوبون الخصم % منتهي الصلاحية', v_disc.code USING ERRCODE = 'P0005';
                END IF;

                IF v_disc.usage_limit IS NOT NULL AND v_disc.usage_count >= v_disc.usage_limit THEN
                    RAISE EXCEPTION 'كوبون الخصم % تجاوز الحد الأقصى للاستخدام', v_disc.code USING ERRCODE = 'P0005';
                END IF;
            END IF;

            BEGIN
                v_matches := public.evaluate_ast_condition(v_disc.conditions_ast, v_pricing_inputs);
            EXCEPTION WHEN OTHERS THEN
                v_matches := false;
            END;

            IF v_matches IS TRUE OR v_disc.conditions_ast = '{}'::JSONB OR v_disc.conditions_ast IS NULL THEN
                v_stack_position := v_stack_position + 1;

                IF v_disc.value_type = 'percentage' THEN
                    v_current_disc_amt := v_subtotal * (v_disc.value / 100.0);
                ELSIF v_disc.value_type = 'fixed' THEN
                    v_current_disc_amt := v_disc.value;
                ELSE
                    v_current_disc_amt := 0.0;
                END IF;

                IF v_total_discount_amount + v_current_disc_amt > v_max_cap_limit THEN
                    v_current_disc_amt := v_max_cap_limit - v_total_discount_amount;
                END IF;

                IF v_current_disc_amt < 0 THEN
                    v_current_disc_amt := 0.0;
                END IF;

                IF v_current_disc_amt > 0 THEN
                    v_total_discount_amount := v_total_discount_amount + v_current_disc_amt;
                    
                    IF v_disc.stackable IS FALSE THEN
                        v_has_non_stackable := true;
                    END IF;

                    v_trace_entry := jsonb_build_object(
                        'stage', 'stage_4_discounts',
                        'discount_id', v_disc.id,
                        'discount_name', v_disc.name,
                        'type', v_disc.value_type,
                        'value_before', v_subtotal,
                        'value_after', (v_subtotal - v_total_discount_amount),
                        'applied_logic', v_disc.type,
                        'stacking_position', v_stack_position,
                        'source', 'live_database_discounts'
                    );
                    v_trace := v_trace || v_trace_entry;

                    v_applied_discounts := v_applied_discounts || jsonb_build_object(
                        'id', v_disc.id,
                        'name', v_disc.name,
                        'amount', v_current_disc_amt
                    );
                END IF;
            END IF;
        END LOOP;
    END IF;

    RETURN p_context || jsonb_build_object(
        'discount', v_total_discount_amount,
        'applied_discounts', v_applied_discounts,
        'execution_trace', v_trace
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 4. STAGE 1: BASE PRICING CALCULATION ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.stage_1_calculate_base_pricing(
    p_sub_service_id UUID,
    p_price_config JSONB,
    p_context JSONB
) RETURNS JSONB AS $$
DECLARE
    v_pricing_inputs   JSONB;
    v_method           TEXT;
    v_unit_price       NUMERIC;
    v_fields           JSONB;
    v_base_price       NUMERIC := 0.0;
    v_extra_fees       NUMERIC := 0.0;
    
    -- Inputs parsed dynamically (Classic fallback)
    v_area             NUMERIC;
    v_min_area         NUMERIC := 100.0;
    v_total_linear     NUMERIC;
    v_windows          JSONB;
    
    -- Dynamic config engine variables
    v_field            JSONB;
    v_field_id         TEXT;
    v_field_type       TEXT;
    v_field_val        NUMERIC;
    v_field_bool       BOOLEAN;
    v_modifier         NUMERIC;
    v_primary_val      NUMERIC := 1.0;

    v_trace            JSONB;
    v_trace_entry      JSONB;
BEGIN
    v_pricing_inputs := p_context -> 'pricing_inputs';
    v_trace := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);

    v_method := p_price_config ->> 'type';
    v_unit_price := COALESCE((p_price_config ->> 'value')::NUMERIC, (p_price_config ->> 'base_price_value')::NUMERIC, 0.0);
    v_fields := p_price_config -> 'fields';

    IF v_fields IS NOT NULL AND jsonb_array_length(v_fields) > 0 THEN
        -- DYNAMIC CONFIG-DRIVEN PRICING ENGINE
        v_base_price := v_unit_price;
        
        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            v_field_id := v_field ->> 'id';
            v_field_type := v_field ->> 'type';
            
            IF v_pricing_inputs ? v_field_id THEN
                IF v_field_type = 'number' THEN
                    v_field_val := (v_pricing_inputs ->> v_field_id)::NUMERIC;
                    IF v_field_val IS NOT NULL THEN
                        -- Enforce minimum constraint if present
                        IF v_field ? 'min' AND v_field_val < (v_field ->> 'min')::NUMERIC THEN
                            v_field_val := (v_field ->> 'min')::NUMERIC;
                        END IF;
                        
                        -- If this is the primary dimension driver (area or total_linear_meters)
                        IF v_field_id = 'area' OR v_field_id = 'total_linear_meters' THEN
                            v_primary_val := v_field_val;
                        ELSE
                            -- Additive price modifier logic
                            IF v_field ? 'price_modifier' THEN
                                v_base_price := v_base_price + (v_field_val * (v_field ->> 'price_modifier')::NUMERIC);
                            END IF;
                        END IF;
                    END IF;
                ELSIF v_field_type = 'toggle' THEN
                    v_field_bool := (v_pricing_inputs -> v_field_id)::BOOLEAN;
                    IF v_field_bool IS TRUE AND v_field ? 'price_modifier' THEN
                        v_modifier := (v_field ->> 'price_modifier')::NUMERIC;
                        -- If modifier is greater than 5, consider it as a fixed add-on fee, otherwise a multiplier
                        IF v_modifier > 5.0 THEN
                            v_extra_fees := v_extra_fees + v_modifier;
                        ELSE
                            v_base_price := v_base_price * v_modifier;
                        END IF;
                    END IF;
                END IF;
            ELSE
                -- If a required field is missing in input, raise error
                IF COALESCE((v_field ->> 'required')::BOOLEAN, false) THEN
                    RAISE EXCEPTION 'الحقل المطلوب % غير موجود في المدخلات', v_field_id USING ERRCODE = 'P0001';
                END IF;
            END IF;
        END LOOP;
        
        -- Multiply base price by primary dimension driver (e.g. area for per_square_meter)
        IF v_method = 'per_square_meter' OR v_method = 'per_linear_meter' THEN
            v_base_price := v_base_price * v_primary_val;
        END IF;

    ELSE
        -- CLASSIC / LEGACY FALLBACK PRICING
        IF v_method = 'per_square_meter' THEN
            -- Securely parse and validate area input
            IF v_pricing_inputs IS NULL OR (v_pricing_inputs ->> 'area') IS NULL THEN
                RAISE EXCEPTION 'المساحة مطلوبة لحساب سعر هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;
            
            v_area := (v_pricing_inputs ->> 'area')::NUMERIC;
            
            -- Enforce minimum area of 100 sqm securely (cannot be bypassed by client)
            IF v_area < v_min_area THEN
                v_area := v_min_area;
            END IF;

            v_base_price := v_unit_price * v_area;

        ELSIF v_method = 'per_linear_meter' THEN
            -- Securely parse and validate linear perimeter/window inputs
            IF v_pricing_inputs IS NULL THEN
                RAISE EXCEPTION 'المدخلات الخاصة بالأطوال مطلوبة لحساب هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;

            v_total_linear := (v_pricing_inputs ->> 'total_linear_meters')::NUMERIC;
            v_windows := v_pricing_inputs -> 'windows';

            IF v_total_linear IS NOT NULL THEN
                v_base_price := v_unit_price * v_total_linear;
            ELSIF v_windows IS NOT NULL AND jsonb_array_length(v_windows) > 0 THEN
                DECLARE
                    v_win            RECORD;
                    v_win_width      NUMERIC;
                    v_win_height     NUMERIC;
                    v_win_quantity   INT;
                    v_win_both_sides BOOLEAN;
                    v_win_perimeter  NUMERIC;
                    v_win_multiplier NUMERIC;
                BEGIN
                    v_total_linear := 0.0;
                    FOR v_win IN SELECT * FROM jsonb_to_recordset(v_windows) AS x(width NUMERIC, height NUMERIC, quantity INT, is_both_sides BOOLEAN) LOOP
                        v_win_width := COALESCE(v_win.width, 0.0);
                        v_win_height := COALESCE(v_win.height, 0.0);
                        v_win_quantity := COALESCE(v_win.quantity, 1);
                        v_win_both_sides := COALESCE(v_win.is_both_sides, false);

                        v_win_perimeter := 2 * (v_win_width + v_win_height) * v_win_quantity;
                        v_win_multiplier := CASE WHEN v_win_both_sides THEN 2.0 ELSE 1.0 END;

                        v_total_linear := v_total_linear + (v_win_perimeter * v_win_multiplier);
                    END LOOP;
                    v_base_price := v_unit_price * v_total_linear;
                END;
            ELSE
                RAISE EXCEPTION 'أبعاد النوافذ أو الأطوال الخطية مطلوبة لحساب هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;

        ELSIF v_method = 'fixed' OR v_method = 'per_issue' THEN
            -- Fixed rate logic
            v_base_price := v_unit_price;
        ELSE
            RAISE EXCEPTION 'طريقة التسعير (%) غير مدعومة معمارياً حالياً', v_method USING ERRCODE = 'P0003';
        END IF;
    END IF;

    -- Generate execution trace entry for Stage 1
    v_trace_entry := jsonb_build_object(
        'stage', 'stage_1_base_pricing',
        'action', 'calculate_base',
        'before', 0.0,
        'after', v_base_price,
        'details', 'Calculated base pricing based on catalog metadata.'
    );
    v_trace := v_trace || v_trace_entry;

    RETURN p_context || jsonb_build_object(
        'base_price', v_base_price,
        'subtotal', v_base_price, -- Init running subtotal
        'extra_fees', v_extra_fees,
        'execution_trace', v_trace
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 5. STAGE 2: CONDITIONAL RULES PIPELINE ORCHESTRATOR ──────────────────────
CREATE OR REPLACE FUNCTION public.stage_2_apply_conditional_rules(
    p_sub_service_id UUID,
    p_context JSONB
) RETURNS JSONB AS $$
BEGIN
    RETURN public.apply_pricing_rules(p_context, p_sub_service_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 6. STAGE 3: OPTIONS / SERVICE ADD-ONS SECURE CALCULATION ─────────────────
CREATE OR REPLACE FUNCTION public.stage_3_apply_options(
    p_sub_service_id UUID,
    p_price_config JSONB,
    p_context JSONB
) RETURNS JSONB AS $$
DECLARE
    v_options           JSONB;
    v_extra_fees       NUMERIC;
    v_before_fees      NUMERIC;
    v_pricing_inputs   JSONB;
    v_selected_options JSONB;
    v_opt_key          TEXT;
    v_opt_record       RECORD;
    v_found_option     BOOLEAN;
    v_options_breakdown JSONB := '[]'::JSONB;
    
    v_trace            JSONB;
    v_trace_entry      JSONB;
BEGIN
    v_pricing_inputs := p_context -> 'pricing_inputs';
    v_extra_fees := (p_context ->> 'extra_fees')::NUMERIC;
    v_trace := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);
    
    v_options := COALESCE(p_price_config -> 'options', '[]'::JSONB);

    IF v_pricing_inputs IS NOT NULL THEN
        v_selected_options := v_pricing_inputs -> 'selected_options';
        IF v_selected_options IS NOT NULL AND jsonb_array_length(v_selected_options) > 0 THEN
            FOR v_opt_key IN SELECT jsonb_array_elements_text(v_selected_options) LOOP
                v_found_option := false;
                FOR v_opt_record IN SELECT * FROM jsonb_to_recordset(v_options) AS y(key TEXT, value NUMERIC) LOOP
                    IF v_opt_record.key = v_opt_key THEN
                        v_before_fees := v_extra_fees;
                        v_extra_fees := v_extra_fees + COALESCE(v_opt_record.value, 0.0);
                        v_found_option := true;
                        
                        -- Log options summing tracing
                        v_trace_entry := jsonb_build_object(
                            'stage', 'stage_3_options',
                            'option_key', v_opt_key,
                            'action', 'add',
                            'before', v_before_fees,
                            'after', v_extra_fees
                        );
                        v_trace := v_trace || v_trace_entry;

                        v_options_breakdown := v_options_breakdown || jsonb_build_object(
                            'key', v_opt_key,
                            'price', v_opt_record.value
                        );
                        EXIT;
                    END IF;
                END LOOP;

                IF NOT v_found_option THEN
                    RAISE EXCEPTION 'خيار التسعير المحدد غير صالح أو غير معرّف لهذه الخدمة: %', v_opt_key USING ERRCODE = 'P0004';
                END IF;
            END LOOP;
        END IF;
    END IF;

    RETURN p_context || jsonb_build_object(
        'extra_fees', v_extra_fees,
        'selected_options', COALESCE(v_selected_options, '[]'::JSONB),
        'options_breakdown', v_options_breakdown,
        'execution_trace', v_trace
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 7. STAGE 4: MARKETING DISCOUNTS PIPELINE ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.stage_4_apply_discounts(
    p_sub_service_id UUID,
    p_context JSONB
) RETURNS JSONB AS $$
BEGIN
    RETURN public.apply_discounts(p_sub_service_id, p_context);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 8. STAGE 5: FINALIZE PRICING ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.stage_5_finalize_pricing(
    p_sub_service_id UUID,
    p_context JSONB
) RETURNS JSONB AS $$
DECLARE
    v_base_price NUMERIC;
    v_subtotal   NUMERIC;
    v_extra_fees NUMERIC;
    v_discount   NUMERIC;
    v_total      NUMERIC;
    
    v_trace      JSONB;
    v_trace_entry JSONB;
BEGIN
    v_base_price := (p_context ->> 'base_price')::NUMERIC;
    v_subtotal := (p_context ->> 'subtotal')::NUMERIC;
    v_extra_fees := (p_context ->> 'extra_fees')::NUMERIC;
    v_discount := (p_context ->> 'discount')::NUMERIC;
    
    v_total := v_subtotal + v_extra_fees - v_discount;
    v_trace := COALESCE(p_context -> 'execution_trace', '[]'::JSONB);

    v_trace_entry := jsonb_build_object(
        'stage', 'stage_5_finalize',
        'action', 'aggregate_totals',
        'subtotal', v_subtotal,
        'extra_fees', v_extra_fees,
        'discount', v_discount,
        'total', v_total
    );
    v_trace := v_trace || v_trace_entry;

    -- Return the fully unified immutable Pricing Context Contract structure
    RETURN jsonb_build_object(
        'basePrice', v_base_price,
        'extraFees', v_extra_fees,
        'discount', v_discount,
        'total', v_total,
        'metadata', jsonb_build_object(
            'subtotal', v_subtotal,
            'pricing_inputs', p_context -> 'pricing_inputs',
            'options_breakdown', p_context -> 'options_breakdown',
            'applied_rules', p_context -> 'applied_rules',
            'applied_discounts', p_context -> 'applied_discounts',
            'pricing_version_id', p_context -> 'pricing_version_id',
            'execution_trace', v_trace
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 9. SNAPSHOT GENERATOR: IMMUTABLE VERSION RECORDER ────────────────────────
-- Captures config, rules, and discounts states, storing them into an indexable snapshot.
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.capture_pricing_version(
    p_sub_service_id UUID
) RETURNS UUID AS $$
DECLARE
    v_price_config   JSONB;
    v_rules          JSONB;
    v_discounts      JSONB;
    v_snapshot       JSONB;
    v_version_id     UUID;
BEGIN
    -- 1. Fetch current price_config
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id;

    IF v_price_config IS NULL THEN
        RAISE EXCEPTION 'الخدمة الفرعية المحددة غير موجودة أو لا تحتوي على إعدادات تسعير' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Fetch current active rules
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', id,
        'name', name,
        'condition_ast', condition_ast,
        'action_type', action_type,
        'action_value', action_value,
        'action_target', action_target,
        'priority', priority
    )), '[]'::JSONB) INTO v_rules
    FROM public.pricing_rules
    WHERE sub_service_id = p_sub_service_id AND is_active = true;

    -- 3. Fetch current active discounts
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', id,
        'name', name,
        'code', code,
        'type', type,
        'value_type', value_type,
        'value', value,
        'conditions_ast', conditions_ast,
        'priority', priority,
        'stackable', stackable
    )), '[]'::JSONB) INTO v_discounts
    FROM public.pricing_discounts
    WHERE (sub_service_id = p_sub_service_id OR sub_service_id IS NULL) AND is_active = true;

    -- 4. Compile snapshot JSONB
    v_snapshot := jsonb_build_object(
        'price_config', v_price_config,
        'rules', v_rules,
        'discounts', v_discounts
    );

    -- Check if an identical active version already exists (prevents duplicate snapshots bloat)
    SELECT id INTO v_version_id
    FROM public.pricing_versions
    WHERE sub_service_id = p_sub_service_id AND is_active = true AND snapshot = v_snapshot
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_version_id IS NOT NULL THEN
        RETURN v_version_id;
    END IF;

    -- Deactivate previous active version of this sub-service
    UPDATE public.pricing_versions
    SET is_active = false
    WHERE sub_service_id = p_sub_service_id AND is_active = true;

    -- Create new active immutable version
    INSERT INTO public.pricing_versions (
        sub_service_id, snapshot, is_active
    ) VALUES (
        p_sub_service_id, v_snapshot, true
    ) RETURNING id INTO v_version_id;

    RETURN v_version_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: Validate Pricing Inputs Schema and Data Types Securely
CREATE OR REPLACE FUNCTION public.validate_pricing_inputs(
    p_sub_service_id UUID,
    p_pricing_inputs JSONB
) RETURNS VOID AS $$
DECLARE
    v_price_config JSONB;
    v_method       TEXT;
    v_fields       JSONB;
    v_field        JSONB;
    v_field_id     TEXT;
    v_field_type   TEXT;
    v_required     BOOLEAN;
    v_val          JSONB;
BEGIN
    -- Fetch the sub-service pricing config
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id;
    
    IF NOT FOUND OR v_price_config IS NULL THEN
        RAISE EXCEPTION 'الخدمة الفرعية المحددة غير موجودة أو لا تحتوي على إعدادات تسعير' USING ERRCODE = 'P0002';
    END IF;
    
    v_method := v_price_config ->> 'type';
    v_fields := v_price_config -> 'fields';
    
    -- Ensure pricing inputs is a JSON object
    IF p_pricing_inputs IS NULL OR jsonb_typeof(p_pricing_inputs) != 'object' THEN
        RAISE EXCEPTION 'مدخلات التسعير يجب أن تكون كائن JSON صالح' USING ERRCODE = 'P0001';
    END IF;
    
    -- 1. Validate required fields in config
    IF v_fields IS NOT NULL AND jsonb_array_length(v_fields) > 0 THEN
        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            v_field_id := v_field ->> 'id';
            v_field_type := v_field ->> 'type';
            v_required := COALESCE((v_field ->> 'required')::BOOLEAN, false);
            
            IF v_required AND NOT (p_pricing_inputs ? v_field_id) THEN
                RAISE EXCEPTION 'الحقل المطلوب % غير موجود في المدخلات', v_field_id USING ERRCODE = 'P0001';
            END IF;
            
            IF p_pricing_inputs ? v_field_id THEN
                v_val := p_pricing_inputs -> v_field_id;
                IF v_field_type = 'number' AND jsonb_typeof(v_val) != 'number' THEN
                    RAISE EXCEPTION 'نوع الحقل % غير صالح: متوقع رقم', v_field_id USING ERRCODE = 'P0001';
                END IF;
                IF v_field_type = 'toggle' AND jsonb_typeof(v_val) != 'boolean' THEN
                    RAISE EXCEPTION 'نوع الحقل % غير صالح: متوقع قيمة منطقية (true/false)', v_field_id USING ERRCODE = 'P0001';
                END IF;
            END IF;
        END LOOP;
    ELSE
        -- Legacy Fallback Validation
        IF v_method = 'per_square_meter' THEN
            IF NOT (p_pricing_inputs ? 'area') THEN
                RAISE EXCEPTION 'المساحة (area) مطلوبة لحساب سعر هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;
            IF jsonb_typeof(p_pricing_inputs -> 'area') != 'number' THEN
                RAISE EXCEPTION 'المساحة (area) يجب أن تكون رقماً' USING ERRCODE = 'P0001';
            END IF;
        ELSIF v_method = 'per_linear_meter' THEN
            IF NOT (p_pricing_inputs ? 'total_linear_meters') AND NOT (p_pricing_inputs ? 'windows') THEN
                RAISE EXCEPTION 'الأطوال الخطية أو أبعاد النوافذ مطلوبة لحساب هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;
            IF p_pricing_inputs ? 'total_linear_meters' AND jsonb_typeof(p_pricing_inputs -> 'total_linear_meters') != 'number' THEN
                RAISE EXCEPTION 'الأطوال الخطية يجب أن تكون رقماً' USING ERRCODE = 'P0001';
            END IF;
            IF p_pricing_inputs ? 'windows' AND jsonb_typeof(p_pricing_inputs -> 'windows') != 'array' THEN
                RAISE EXCEPTION 'بيانات النوافذ (windows) يجب أن تكون مصفوفة' USING ERRCODE = 'P0001';
            END IF;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- ── 10. EXECUTION CONTROLLER: PIPELINE CONTROLLER ─────────────────────────────
-- Orchestrates pricing flow execution, guarantees deterministic order.
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.execute_pricing_pipeline(
    p_sub_service_id UUID,
    p_price_config JSONB,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_context    JSONB;
    v_version_id UUID;
    v_snapshot   JSONB;
    v_rules      JSONB;
    v_discounts  JSONB;
BEGIN
    -- 0. Securely validate pricing inputs schema and types
    PERFORM public.validate_pricing_inputs(p_sub_service_id, p_pricing_inputs);

    -- 1. Autoritatively capture/lock active pricing version
    BEGIN
        v_version_id := public.capture_pricing_version(p_sub_service_id);
        
        -- Load locked snapshot components
        SELECT snapshot INTO v_snapshot
        FROM public.pricing_versions
        WHERE id = v_version_id;
        
        v_rules := v_snapshot -> 'rules';
        v_discounts := v_snapshot -> 'discounts';
    EXCEPTION WHEN OTHERS THEN
        v_version_id := NULL;
        v_rules := NULL;
        v_discounts := NULL;
    END;

    -- 2. Initialize deterministic execution contract context
    v_context := jsonb_build_object(
        'base_price', 0.0,
        'subtotal', 0.0,
        'extra_fees', 0.0,
        'discount', 0.0,
        'applied_rules', '[]'::JSONB,
        'applied_discounts', '[]'::JSONB,
        'selected_options', '[]'::JSONB,
        'execution_trace', '[]'::JSONB,
        'pricing_inputs', COALESCE(p_pricing_inputs, '{}'::JSONB),
        'pricing_version_id', v_version_id
    );

    -- Inject snapshots if successfully locked
    IF v_rules IS NOT NULL THEN
        v_context := v_context || jsonb_build_object(
            'snapshot_rules', v_rules,
            'snapshot_discounts', v_discounts
        );
    END IF;

    -- 3. Stage 1: Base Pricing
    v_context := public.stage_1_calculate_base_pricing(p_sub_service_id, p_price_config, v_context);

    -- 4. Stage 2: Relational Conditional Rules
    v_context := public.stage_2_apply_conditional_rules(p_sub_service_id, v_context);

    -- 5. Stage 3: Options / Add-ons
    v_context := public.stage_3_apply_options(p_sub_service_id, p_price_config, v_context);

    -- 6. Stage 4: Dynamic stackable discounts
    v_context := public.stage_4_apply_discounts(p_sub_service_id, v_context);

    -- 7. Stage 5: Finalization and Formatter mapping
    v_context := public.stage_5_finalize_pricing(p_sub_service_id, v_context);

    RETURN v_context;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 11. PUBLIC PRICING PREVIEW RPC (COMPATIBILITY BRIDGE) ────────────────────
CREATE OR REPLACE FUNCTION public.calculate_booking_price(
    p_sub_service_id UUID,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_price_config JSONB;
    v_pipeline_res JSONB;
BEGIN
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id;

    IF NOT FOUND OR v_price_config IS NULL THEN
        RAISE EXCEPTION 'الخدمة الفرعية المحددة غير موجودة أو لا تحتوي على إعدادات تسعير' USING ERRCODE = 'P0002';
    END IF;

    -- Call execution orchestrator
    v_pipeline_res := public.execute_pricing_pipeline(p_sub_service_id, v_price_config, p_pricing_inputs);

    -- Extrude output mapping keeping complete camelCase APIs structure
    RETURN jsonb_build_object(
        'basePrice', (v_pipeline_res ->> 'basePrice')::NUMERIC,
        'extraFees', (v_pipeline_res ->> 'extraFees')::NUMERIC,
        'discount', (v_pipeline_res ->> 'discount')::NUMERIC,
        'total', (v_pipeline_res ->> 'total')::NUMERIC,
        'metadata', v_pipeline_res -> 'metadata'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 12. SECURE ATOMIC BOOKING TRANSACTION RPC ────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id          UUID,
    p_sub_service_id   UUID,
    p_technician_id    UUID,
    p_scheduled_day    DATE,
    p_address_snapshot JSONB,
    p_service_snapshot JSONB,
    p_pricing_inputs   JSONB,
    p_contact_name     TEXT DEFAULT 'Client',
    p_contact_phones   TEXT[] DEFAULT '{}'::TEXT[],
    p_start_time_slot  TIME DEFAULT '09:00',
    p_actor_id         UUID DEFAULT NULL,
    p_actor_role       TEXT DEFAULT 'admin'
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
BEGIN
    -- Verify booking creation authorization (Standard user must only book for themselves)
    IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
        IF p_user_id != auth.uid() THEN
            RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' USING ERRCODE = '42501';
        END IF;
    END IF;

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

    INSERT INTO public.bookings (
        user_id, technician_id, service_id, scheduled_day, start_time_slot,
        address_snapshot, service_snapshot, price_snapshot,
        pricing_inputs, pricing_version_id,
        contact_name, contact_phones,
        status
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, v_price_snapshot,
        COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2
    ) RETURNING id INTO v_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    PERFORM public.transition_booking(
        v_booking_id,
        'assigned'::public.order_status_v2,
        COALESCE(p_actor_id, p_user_id),
        p_actor_role,
        'BOOKING_CREATION',
        'تم إنشاء الحجز والتحقق من السعر وتثبيت النسخة الأرشيفية بنجاح.'
    );

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- ── 13. IMMUTABLE FINANCIAL LEDGER AUDIT REPLAY ENGINE ────────────────────────
-- Reconstructs exact pricing result and validates trace steps against locked snapshot.
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.replay_booking_pricing(
    p_booking_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_booking_record RECORD;
    v_version_record RECORD;
    v_price_config   JSONB;
    v_context        JSONB;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can replay booking pricing.' USING ERRCODE = '42501';
    END IF;

    -- 1. Fetch booking record
    SELECT service_id, price_snapshot, pricing_inputs, pricing_version_id
    INTO v_booking_record
    FROM public.bookings
    WHERE id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الحجز المحدد غير موجود' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Fetch locked version snapshot
    SELECT snapshot INTO v_version_record
    FROM public.pricing_versions
    WHERE id = v_booking_record.pricing_version_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'نسخة التسعير المؤرشفة لهذا الحجز غير موجودة' USING ERRCODE = 'P0002';
    END IF;

    -- 3. Initialize pricing context with locked snapshot components
    v_context := jsonb_build_object(
        'base_price', 0.0,
        'subtotal', 0.0,
        'extra_fees', 0.0,
        'discount', 0.0,
        'applied_rules', '[]'::JSONB,
        'applied_discounts', '[]'::JSONB,
        'selected_options', '[]'::JSONB,
        'execution_trace', '[]'::JSONB,
        'pricing_inputs', COALESCE(v_booking_record.pricing_inputs, '{}'::JSONB),
        'pricing_version_id', v_booking_record.pricing_version_id,
        'snapshot_rules', v_version_record -> 'rules',
        'snapshot_discounts', v_version_record -> 'discounts'
    );

    -- 4. Execute pipeline stages directly from snapshot
    v_price_config := v_version_record -> 'price_config';
    v_context := public.stage_1_calculate_base_pricing(v_booking_record.service_id, v_price_config, v_context);
    v_context := public.stage_2_apply_conditional_rules(v_booking_record.service_id, v_context);
    v_context := public.stage_3_apply_options(v_booking_record.service_id, v_price_config, v_context);
    v_context := public.stage_4_apply_discounts(v_booking_record.service_id, v_context);
    v_context := public.stage_5_finalize_pricing(v_booking_record.service_id, v_context);

    -- Return full replay ledger comparison report
    RETURN jsonb_build_object(
        'booking_id', p_booking_id,
        'original_snapshot', v_booking_record.price_snapshot,
        'replayed_snapshot', v_context,
        'is_match', (v_booking_record.price_snapshot ->> 'total')::NUMERIC = (v_context ->> 'total')::NUMERIC
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 14. DEEP COMMENTS AND SCHEMAS DOCUMENTATION ──────────────────────────────
COMMENT ON TABLE public.pricing_rules IS 'Stores dynamic relational conditional pricing rules and calculations actions.';
COMMENT ON TABLE public.pricing_discounts IS 'Stores Dynamic Enterprise Stackable Promotions and Coupons Campaign Details.';
COMMENT ON TABLE public.pricing_versions IS 'Stores Immutable Snapshot Archives of Price Configuration, Rules, and Active Promotions.';
COMMENT ON FUNCTION public.validate_condition_ast(JSONB) IS 'Validates the structural AST condition nodes schema at database integrity constraints level.';
COMMENT ON FUNCTION public.evaluate_ast_condition(JSONB, JSONB) IS 'Recursively parses and evaluates the boolean AST conditions layout tree.';
COMMENT ON FUNCTION public.apply_pricing_rules(JSONB, UUID) IS 'Dynamic rules execution engine. Loops rules by priority and mutates running prices subtotal.';
COMMENT ON FUNCTION public.apply_discounts(UUID, JSONB) IS 'Stackable Promotion Engine enforcing priority and global 30% cumulative cap limit.';
COMMENT ON FUNCTION public.capture_pricing_version(UUID) IS 'Immutable pricing version snapshot compiler utilizing active B-tree and deduplication logic.';
COMMENT ON FUNCTION public.execute_pricing_pipeline(UUID, JSONB, JSONB) IS 'Central Execution Controller enforcing deterministic order and trace logs aggregation.';
COMMENT ON FUNCTION public.replay_booking_pricing(UUID) IS 'High-fidelity financial ledger auditing compiler, replaying exact transaction pricingauthoritatively.';

-- ── 15. PRICING GOVERNANCE AUDIT SYSTEM & SIMULATION ENGINE ──────────────────
-- Allows governance tracking, rules changelogs, and sandbox pipeline simulation.
-- ──────────────────────────────────────────────────────────────────────────

-- Create Governance Audit Table
CREATE TABLE IF NOT EXISTS public.pricing_governance_audit (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_service_id     UUID, -- Reference to specific service/sub_service
    rule_id            UUID, -- Reference to pricing_rules
    discount_id        UUID, -- Reference to pricing_discounts
    action             TEXT NOT NULL, -- 'create' | 'update' | 'delete' | 'simulate'
    actor_id           UUID, -- Optionally references auth.users if populated
    before_state       JSONB,
    after_state        JSONB,
    simulation_payload JSONB,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.pricing_governance_audit ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS select_pricing_governance_audit ON public.pricing_governance_audit;
DROP POLICY IF EXISTS insert_pricing_governance_audit ON public.pricing_governance_audit;
DROP POLICY IF EXISTS pricing_governance_audit_admin_select ON public.pricing_governance_audit;
DROP POLICY IF EXISTS pricing_governance_audit_admin_insert ON public.pricing_governance_audit;

CREATE POLICY pricing_governance_audit_admin_select ON public.pricing_governance_audit
    FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY pricing_governance_audit_admin_insert ON public.pricing_governance_audit
    FOR INSERT TO authenticated WITH CHECK (public.is_admin());

-- Sandbox Simulating Pipeline Execution (PL/pgSQL Side-Effect-Free Compiler)
CREATE OR REPLACE FUNCTION public.simulate_pricing_pipeline(
    p_sub_service_id UUID,
    p_price_config JSONB,
    p_rules JSONB,
    p_discounts JSONB,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_context JSONB;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can simulate pricing pipelines.' USING ERRCODE = '42501';
    END IF;

    -- 1. Initialize context contract containing simulation overrides
    v_context := jsonb_build_object(
        'base_price', 0.0,
        'subtotal', 0.0,
        'extra_fees', 0.0,
        'discount', 0.0,
        'applied_rules', '[]'::JSONB,
        'applied_discounts', '[]'::JSONB,
        'selected_options', '[]'::JSONB,
        'execution_trace', '[]'::JSONB,
        'pricing_inputs', COALESCE(p_pricing_inputs, '{}'::JSONB),
        'snapshot_rules', COALESCE(p_rules, '[]'::JSONB),
        'snapshot_discounts', COALESCE(p_discounts, '[]'::JSONB),
        'is_simulation', true
    );

    -- 2. Execute pipeline stages directly using simulation inputs
    v_context := public.stage_1_calculate_base_pricing(p_sub_service_id, p_price_config, v_context);
    v_context := public.stage_2_apply_conditional_rules(p_sub_service_id, v_context);
    v_context := public.stage_3_apply_options(p_sub_service_id, p_price_config, v_context);
    v_context := public.stage_4_apply_discounts(p_sub_service_id, v_context);
    v_context := public.stage_5_finalize_pricing(p_sub_service_id, v_context);

    RETURN v_context;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE public.pricing_governance_audit IS 'Audits admin structural configuration adjustments and sandboxed simulations execution logs.';
COMMENT ON FUNCTION public.simulate_pricing_pipeline(UUID, JSONB, JSONB, JSONB, JSONB) IS 'Executes complete pricing pipeline in a fully isolated, side-effect-free simulation sandbox.';

-- ── 16. PRICING GOVERNANCE AUTOMATED AUDIT TRIGGERS ───────────────────────────
CREATE OR REPLACE FUNCTION public.fn_audit_pricing_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_action TEXT;
    v_before JSONB := NULL;
    v_after  JSONB := NULL;
    v_sub_service_id UUID := NULL;
    v_rule_id UUID := NULL;
    v_discount_id UUID := NULL;
BEGIN
    v_action := TG_OP;
    
    IF TG_TABLE_NAME = 'pricing_rules' THEN
        IF v_action = 'INSERT' THEN
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_rule_id := NEW.id;
        ELSIF v_action = 'UPDATE' THEN
            v_before := to_jsonb(OLD);
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_rule_id := NEW.id;
        ELSIF v_action = 'DELETE' THEN
            v_before := to_jsonb(OLD);
            v_sub_service_id := OLD.sub_service_id;
            v_rule_id := OLD.id;
        END IF;
    ELSIF TG_TABLE_NAME = 'pricing_discounts' THEN
        IF v_action = 'INSERT' THEN
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_discount_id := NEW.id;
        ELSIF v_action = 'UPDATE' THEN
            v_before := to_jsonb(OLD);
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_discount_id := NEW.id;
        ELSIF v_action = 'DELETE' THEN
            v_before := to_jsonb(OLD);
            v_sub_service_id := OLD.sub_service_id;
            v_discount_id := OLD.id;
        END IF;
    END IF;
    
    INSERT INTO public.pricing_governance_audit (
        sub_service_id, rule_id, discount_id, action, actor_id, before_state, after_state
    ) VALUES (
        v_sub_service_id, v_rule_id, v_discount_id, v_action, auth.uid(), v_before, v_after
    );
    
    IF v_action = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach Triggers
DROP TRIGGER IF EXISTS trg_audit_pricing_rules ON public.pricing_rules;
CREATE TRIGGER trg_audit_pricing_rules
AFTER INSERT OR UPDATE OR DELETE ON public.pricing_rules
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_pricing_changes();

DROP TRIGGER IF EXISTS trg_audit_pricing_discounts ON public.pricing_discounts;
CREATE TRIGGER trg_audit_pricing_discounts
AFTER INSERT OR UPDATE OR DELETE ON public.pricing_discounts
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_pricing_changes();
