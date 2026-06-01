-- Migration ID: 42_add_computed_fields
-- Description: Add computed_fields column to services, and implement computed fields engine.

BEGIN;

-- 1. Alter public.services table to add computed_fields column
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS computed_fields JSONB DEFAULT '[]'::JSONB;

-- 2. Create the computed fields evaluation helper function
CREATE OR REPLACE FUNCTION public.calculate_computed_fields(
    p_inputs JSONB,
    p_computed_fields JSONB
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_field JSONB;
    v_id TEXT;
    v_formula TEXT;
    v_replaced_formula TEXT;
    v_eval_query TEXT;
    v_val NUMERIC;
    v_token TEXT;
    v_token_val JSONB;
BEGIN
    v_result := COALESCE(p_inputs, '{}'::JSONB);
    
    IF p_computed_fields IS NULL OR jsonb_typeof(p_computed_fields) != 'array' OR jsonb_array_length(p_computed_fields) = 0 THEN
        RETURN v_result;
    END IF;

    FOR v_field IN SELECT * FROM jsonb_array_elements(p_computed_fields) LOOP
        v_id := v_field ->> 'id';
        v_formula := v_field ->> 'formula';
        
        IF v_id IS NOT NULL AND v_formula IS NOT NULL AND v_formula != '' THEN
            v_replaced_formula := v_formula;
            
            -- Extract and replace all tokens matching {token_name}
            FOR v_token IN SELECT DISTINCT (regexp_matches(v_formula, '\{([a-zA-Z0-9_]+)\}', 'g'))[1] LOOP
                v_token_val := v_result -> v_token;
                IF v_token_val IS NULL OR jsonb_typeof(v_token_val) != 'number' THEN
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
                ELSE
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', (v_token_val)::TEXT);
                END IF;
            END LOOP;

            -- Safety Check: The resulting string must strictly contain ONLY numbers, decimal points, spaces, and math symbols: +, -, *, /, (, )
            IF v_replaced_formula ~ '^[0-9\.\+\-\*\/\(\)\s]+$' THEN
                v_eval_query := 'SELECT (' || v_replaced_formula || ')::NUMERIC;';
                BEGIN
                    EXECUTE v_eval_query INTO v_val;
                    v_result := v_result || jsonb_build_object(v_id, v_val);
                EXCEPTION WHEN OTHERS THEN
                    RAISE EXCEPTION 'خطأ في حساب الحقل المحسوب %: %', v_id, SQLERRM USING ERRCODE = 'P0001';
                END;
            ELSE
                RAISE EXCEPTION 'صيغة الحقل المحسوب % غير آمنة أو غير صالحة: %', v_id, v_replaced_formula USING ERRCODE = 'P0001';
            END IF;
        END IF;
    END LOOP;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-define execute_pricing_pipeline to calculate computed fields before validation
CREATE OR REPLACE FUNCTION public.execute_pricing_pipeline(
    p_sub_service_id TEXT,
    p_price_config JSONB,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_context        JSONB;
    v_version_id     UUID;
    v_snapshot       JSONB;
    v_rules          JSONB;
    v_discounts      JSONB;
    v_computed_fields JSONB;
    v_calculated_inputs JSONB;
BEGIN
    -- Fetch computed_fields from the database
    SELECT computed_fields INTO v_computed_fields
    FROM public.services
    WHERE id = p_sub_service_id AND is_bookable = true;

    -- Calculate computed fields dynamically
    v_calculated_inputs := public.calculate_computed_fields(p_pricing_inputs, v_computed_fields);

    -- 0. Securely validate pricing inputs schema and types
    PERFORM public.validate_pricing_inputs(p_sub_service_id, v_calculated_inputs);

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
        'pricing_inputs', COALESCE(v_calculated_inputs, '{}'::JSONB),
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

-- 4. Re-define simulate_pricing_pipeline (5-parameter variant) to calculate computed fields
CREATE OR REPLACE FUNCTION public.simulate_pricing_pipeline(
    p_sub_service_id TEXT,
    p_price_config JSONB,
    p_rules JSONB,
    p_discounts JSONB,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_context JSONB;
    v_computed_fields JSONB;
    v_calculated_inputs JSONB;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can simulate pricing pipelines.' USING ERRCODE = '42501';
    END IF;

    -- Extract computed_fields from p_price_config if present (for unsaved draft simulation), 
    -- otherwise fetch from public.services database table
    IF p_price_config ? 'computed_fields' THEN
        v_computed_fields := p_price_config -> 'computed_fields';
    ELSE
        SELECT computed_fields INTO v_computed_fields
        FROM public.services
        WHERE id = p_sub_service_id AND is_bookable = true;
    END IF;

    -- Calculate computed fields dynamically
    v_calculated_inputs := public.calculate_computed_fields(p_pricing_inputs, v_computed_fields);

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
        'pricing_inputs', COALESCE(v_calculated_inputs, '{}'::JSONB),
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

COMMIT;
