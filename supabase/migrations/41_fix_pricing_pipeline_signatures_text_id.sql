-- ==============================================================================
-- Fresh Home: Fix pricing pipeline functions and parameters for TEXT service IDs
-- Migration ID: 41_fix_pricing_pipeline_signatures_text_id
-- ==============================================================================

BEGIN;

-- ── 1. DROP OLD UUID-BASED FUNCTION SIGNATURES ────────────────────────────────

DROP FUNCTION IF EXISTS public.apply_pricing_rules(JSONB, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.stage_1_calculate_base_pricing(UUID, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.stage_2_apply_conditional_rules(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.stage_3_apply_options(UUID, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.stage_4_apply_discounts(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.stage_5_finalize_pricing(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.apply_discounts(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.validate_pricing_inputs(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.capture_pricing_version(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.execute_pricing_pipeline(UUID, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.simulate_pricing_pipeline(UUID, JSONB, JSONB, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME) CASCADE;
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_available_technicians(UUID, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.get_available_days(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.get_fleet_capacity_dashboard(DATE, DATE, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_technician_capacity_report(DATE, UUID) CASCADE;


-- ── 2. CREATE NEW TEXT-BASED FUNCTION SIGNATURES ──────────────────────────────

-- A. validate_pricing_inputs
CREATE OR REPLACE FUNCTION public.validate_pricing_inputs(
    p_sub_service_id TEXT,
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
    -- Fetch the sub-service pricing config from public.services (previously sub_services)
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id AND is_bookable = true;
    
    IF NOT FOUND OR v_price_config IS NULL THEN
        RAISE EXCEPTION 'الخدمة الفرعية المحددة غير موجودة أو لا تحتوي على إعدادات تسعير' USING ERRCODE = 'P0002';
    END IF;
    
    v_method := v_price_config ->> 'type';
    v_fields := v_price_config -> 'fields';
    
    -- Ensure pricing inputs is a JSON object
    IF p_pricing_inputs IS NULL OR jsonb_typeof(p_pricing_inputs) != 'object' THEN
        RAISE EXCEPTION 'مدخلات التسعير يجب أن تكون كائن JSON صالح' USING ERRCODE = 'P0001';
    END IF;
    
    -- Validate required fields in config
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


-- B. evaluate_ast_condition (already has JSONB params, keeping unchanged but ensuring existence)

-- C. apply_pricing_rules
CREATE OR REPLACE FUNCTION public.apply_pricing_rules(
    p_context JSONB,
    p_sub_service_id TEXT
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


-- D. apply_discounts
CREATE OR REPLACE FUNCTION public.apply_discounts(
    p_sub_service_id TEXT,
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


-- E. stage_1_calculate_base_pricing
CREATE OR REPLACE FUNCTION public.stage_1_calculate_base_pricing(
    p_sub_service_id TEXT,
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
        'subtotal', v_base_price,
        'extra_fees', v_extra_fees,
        'execution_trace', v_trace
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- F. stage_2_apply_conditional_rules
CREATE OR REPLACE FUNCTION public.stage_2_apply_conditional_rules(
    p_sub_service_id TEXT,
    p_context JSONB
) RETURNS JSONB AS $$
BEGIN
    RETURN public.apply_pricing_rules(p_context, p_sub_service_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- G. stage_3_apply_options
CREATE OR REPLACE FUNCTION public.stage_3_apply_options(
    p_sub_service_id TEXT,
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
                            'after', v_extra_fees,
                            'source', 'live_price_config_options'
                        );
                        v_trace := v_trace || v_trace_entry;

                        v_options_breakdown := v_options_breakdown || jsonb_build_object(
                            'key', v_opt_key,
                            'value', v_opt_record.value
                        );
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    END IF;

    RETURN p_context || jsonb_build_object(
        'extra_fees', v_extra_fees,
        'options_breakdown', v_options_breakdown,
        'execution_trace', v_trace
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- H. stage_4_apply_discounts
CREATE OR REPLACE FUNCTION public.stage_4_apply_discounts(
    p_sub_service_id TEXT,
    p_context JSONB
) RETURNS JSONB AS $$
BEGIN
    RETURN public.apply_discounts(p_sub_service_id, p_context);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- I. stage_5_finalize_pricing
CREATE OR REPLACE FUNCTION public.stage_5_finalize_pricing(
    p_sub_service_id TEXT,
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


-- J. capture_pricing_version
CREATE OR REPLACE FUNCTION public.capture_pricing_version(
    p_sub_service_id TEXT
) RETURNS UUID AS $$
DECLARE
    v_price_config   JSONB;
    v_rules          JSONB;
    v_discounts      JSONB;
    v_snapshot       JSONB;
    v_version_id     UUID;
BEGIN
    -- 1. Fetch current price_config from unified services table
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id AND is_bookable = true;

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
    WHERE sub_service_id = p_sub_service_id
      AND snapshot = v_snapshot
      AND is_active = true
    LIMIT 1;

    IF v_version_id IS NOT NULL THEN
        RETURN v_version_id;
    END IF;

    -- Deduplicate: Deactivate previous versions for this sub-service
    UPDATE public.pricing_versions
    SET is_active = false
    WHERE sub_service_id = p_sub_service_id;

    -- Insert new authoritative version snapshot
    INSERT INTO public.pricing_versions (
        sub_service_id,
        snapshot,
        is_active
    ) VALUES (
        p_sub_service_id,
        v_snapshot,
        true
    ) RETURNING id INTO v_version_id;

    RETURN v_version_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- K. execute_pricing_pipeline
CREATE OR REPLACE FUNCTION public.execute_pricing_pipeline(
    p_sub_service_id TEXT,
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


-- L. simulate_pricing_pipeline (5-parameter variant)
CREATE OR REPLACE FUNCTION public.simulate_pricing_pipeline(
    p_sub_service_id TEXT,
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


-- M. simulate_pricing_pipeline (3-parameter client-side wrapper overload to fix PGRST202)
CREATE OR REPLACE FUNCTION public.simulate_pricing_pipeline(
    p_inputs JSONB,
    p_options JSONB,
    p_service_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_price_config JSONB;
    v_rules          JSONB;
    v_discounts      JSONB;
    v_merged_inputs  JSONB;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can simulate pricing pipelines.' USING ERRCODE = '42501';
    END IF;

    -- 1. Fetch current price_config from unified services table
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_service_id AND is_bookable = true;

    IF v_price_config IS NULL THEN
        RAISE EXCEPTION 'الخدمة الفرعية المحددة غير موجودة أو لا تحتوي على إعدادات تسعير' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Fetch active rules for this sub-service
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
    WHERE sub_service_id = p_service_id AND is_active = true;

    -- 3. Fetch active discounts for this sub-service
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
    WHERE (sub_service_id = p_service_id OR sub_service_id IS NULL) AND is_active = true;

    -- Merge options as selected_options in inputs contract if present
    v_merged_inputs := COALESCE(p_inputs, '{}'::JSONB);
    IF p_options IS NOT NULL AND jsonb_array_length(p_options) > 0 THEN
        v_merged_inputs := v_merged_inputs || jsonb_build_object('selected_options', p_options);
    END IF;

    -- 4. Call standard simulation pipeline
    RETURN public.simulate_pricing_pipeline(
        p_service_id,
        v_price_config,
        v_rules,
        v_discounts,
        v_merged_inputs
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- N. get_available_technicians
CREATE OR REPLACE FUNCTION public.get_available_technicians(
    p_sub_service_id TEXT,
    p_date           DATE
) RETURNS TABLE (
    technician_id   UUID,
    first_name      TEXT,
    last_name       TEXT,
    avatar_url      TEXT,
    rating          DECIMAL,
    current_load    BIGINT,
    max_capacity    INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH pool_mapping AS (
        SELECT
            ts.technician_id,
            ts.capacity_pool_id,
            cp.max_daily_capacity
        FROM public.technician_skills ts
        JOIN public.capacity_pools cp ON ts.capacity_pool_id = cp.id
        WHERE ts.sub_service_id = p_sub_service_id
          AND ts.is_active = true
    ),
    pool_load AS (
        SELECT
            pm.technician_id,
            pm.capacity_pool_id,
            COUNT(b.id) FILTER (WHERE b.technician_id = pm.technician_id) AS assigned_load,
            COUNT(b.id) FILTER (WHERE b.technician_id IS NULL) AS unassigned_load
        FROM pool_mapping pm
        LEFT JOIN public.bookings b 
               ON b.service_id      = p_sub_service_id
              AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE = p_date
              AND b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
        GROUP BY pm.technician_id, pm.capacity_pool_id
    )
    SELECT
        tp.user_id,
        pr.first_name,
        pr.last_name,
        pr.avatar_url,
        tp.rating,
        (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::BIGINT,
        pm.max_daily_capacity
    FROM pool_mapping pm
    JOIN public.technician_profiles tp ON tp.user_id = pm.technician_id
    JOIN public.profiles pr ON pr.id = tp.user_id
    JOIN pool_load pl ON pl.technician_id = pm.technician_id
                     AND pl.capacity_pool_id = pm.capacity_pool_id
    WHERE tp.is_available = true
      AND pr.account_status = 'active'
      AND (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0)) < pm.max_daily_capacity
    ORDER BY tp.rating DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- O. get_available_days
CREATE OR REPLACE FUNCTION public.get_available_days(
    p_sub_service_id TEXT,
    p_start_date     DATE,
    p_end_date       DATE
) RETURNS TABLE (
    available_date DATE,
    is_available   BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.day::DATE,
        EXISTS (
            SELECT 1
            FROM public.get_available_technicians(p_sub_service_id, d.day::DATE)
            LIMIT 1
        ) AS is_available
    FROM generate_series(p_start_date, p_end_date, '1 day'::INTERVAL) AS d(day);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- P. get_fleet_capacity_dashboard
CREATE OR REPLACE FUNCTION public.get_fleet_capacity_dashboard(
    p_start_date DATE,
    p_end_date   DATE,
    p_main_service_id TEXT DEFAULT NULL
) RETURNS TABLE (
    service_id             TEXT,
    service_title         JSONB,
    target_date            DATE,
    total_technicians      BIGINT,
    total_capacity        BIGINT,
    total_booked          BIGINT,
    available_capacity    BIGINT,
    utilization_percentage DECIMAL
) AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the fleet capacity dashboard.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT d.day::DATE AS target_date 
        FROM generate_series(p_start_date, p_end_date, '1 day'::INTERVAL) AS d(day)
    ),
    service_list AS (
        SELECT ss.id, ss.title, ss.parent_id
        FROM public.services ss
        WHERE ss.is_bookable = true
          AND (p_main_service_id IS NULL OR ss.parent_id = p_main_service_id)
    ),
    tech_capabilities AS (
        SELECT
            ds.target_date,
            sl.id AS sub_service_id,
            ts.technician_id,
            ts.capacity_pool_id,
            CASE
                WHEN co.is_blocked = TRUE THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_capacity
        FROM date_series ds
        CROSS JOIN service_list sl
        JOIN public.technician_skills ts ON ts.sub_service_id = sl.id
        JOIN public.capacity_pools cp    ON cp.id = ts.capacity_pool_id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = ts.capacity_pool_id
              AND co_inner.technician_id = ts.technician_id
              AND co_inner.override_date = ds.target_date
            ORDER BY co_inner.override_date DESC, co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE ts.is_active = true
    ),
    service_load AS (
        SELECT
            (b.scheduled_day AT TIME ZONE 'UTC')::DATE AS target_date,
            b.service_id,
            COUNT(b.id) AS booked_count
        FROM public.bookings b
        WHERE b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
          AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE BETWEEN p_start_date AND p_end_date
        GROUP BY 1, 2
    )
    SELECT
        sl.id,
        sl.title,
        ds.target_date,
        COUNT(DISTINCT tc.technician_id) FILTER (WHERE tc.effective_capacity > 0),
        SUM(tc.effective_capacity)::BIGINT,
        COALESCE(l.booked_count, 0)::BIGINT,
        (SUM(tc.effective_capacity) - COALESCE(l.booked_count, 0))::BIGINT,
        ROUND(
            (COALESCE(l.booked_count, 0)::DECIMAL / NULLIF(SUM(tc.effective_capacity), 0)) * 100, 
            2
        )
    FROM date_series ds
    CROSS JOIN service_list sl
    LEFT JOIN tech_capabilities tc ON tc.target_date = ds.target_date AND tc.sub_service_id = sl.id
    LEFT JOIN service_load l      ON l.target_date = ds.target_date AND l.service_id = sl.id
    GROUP BY sl.id, sl.title, ds.target_date
    ORDER BY ds.target_date, sl.title->>'en';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- Q. get_technician_capacity_report
CREATE OR REPLACE FUNCTION public.get_technician_capacity_report(
    p_date DATE,
    p_sub_service_id TEXT DEFAULT NULL
) RETURNS TABLE (
    technician_id    UUID,
    first_name       TEXT,
    last_name        TEXT,
    pool_title       TEXT,
    effective_cap    INTEGER,
    current_load     BIGINT,
    is_blocked       BOOLEAN,
    status           TEXT
) AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the technician capacity report.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH tech_stats AS (
        SELECT
            tp.user_id,
            pr.first_name,
            pr.last_name,
            cp.title AS pool_title,
            cp.id AS pool_id,
            CASE
                WHEN co.is_blocked = TRUE THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_capacity,
            COALESCE(co.is_blocked, false) AS blocked_flag,
            (
                SELECT COUNT(*)
                FROM public.bookings b
                JOIN public.technician_skills s ON s.sub_service_id = b.service_id
                WHERE s.capacity_pool_id = cp.id
                  AND b.scheduled_day::DATE = p_date
                  AND (b.technician_id = tp.user_id OR b.technician_id IS NULL)
                  AND b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
            ) AS load_count
        FROM public.technician_profiles tp
        JOIN public.profiles pr ON pr.id = tp.user_id
        JOIN public.capacity_pools cp ON cp.technician_id = tp.user_id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = cp.id
              AND co_inner.technician_id = tp.user_id
              AND co_inner.override_date = p_date
            ORDER BY co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE (p_sub_service_id IS NULL OR EXISTS (
            SELECT 1 FROM public.technician_skills ts 
            WHERE ts.technician_id = tp.user_id AND ts.sub_service_id = p_sub_service_id
        ))
    )
    SELECT
        t.user_id,
        t.first_name,
        t.last_name,
        t.pool_title,
        t.effective_capacity,
        t.load_count::BIGINT,
        t.blocked_flag,
        CASE
            WHEN t.blocked_flag THEN 'blocked'
            WHEN t.load_count > t.effective_capacity THEN 'overloaded'
            WHEN t.load_count = t.effective_capacity THEN 'full'
            WHEN t.load_count = 0 THEN 'idle'
            ELSE 'active'
        END::TEXT AS status
    FROM tech_stats t;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- R. create_atomic_booking (V5.1 text service_id)
CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id          UUID,
    p_sub_service_id   TEXT,
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

    -- Load price configuration
    SELECT price_config INTO v_price_config
    FROM public.services
    WHERE id = p_sub_service_id AND is_bookable = true;

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


-- S. replay_booking_pricing
CREATE OR REPLACE FUNCTION public.replay_booking_pricing(
    p_booking_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_booking_record RECORD;
    v_version_record JSONB;
    v_price_config   JSONB;
    v_context        JSONB;
BEGIN
    -- 1. Load active booking record inputs and parameters
    SELECT service_id, pricing_inputs, pricing_version_id, price_snapshot
    INTO v_booking_record
    FROM public.bookings
    WHERE id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الحجز المطلوب غير موجود' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Load the locked immutable pricing version snapshot
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

COMMIT;
