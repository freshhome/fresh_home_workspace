-- Migration ID: 49_formula_min_constraint_handling
-- Description: Update stage_1_calculate_base_pricing to support min constraint verification
-- in formula-based calculations. Clamps numerical tokens (like {area}) to their defined min value dynamically per service.

BEGIN;

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

    -- Formula-based engine variables
    v_formula          TEXT;
    v_replaced_formula TEXT;
    v_token            TEXT;
    v_token_val        JSONB;
    v_eval_query       TEXT;

    -- Classic fallback input variables
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
    v_formula := p_price_config ->> 'base_price_formula';

    -- ══════════════════════════════════════════════════════════════════════
    -- PATH A: FORMULA-BASED ENGINE (when base_price_formula is defined)
    -- ══════════════════════════════════════════════════════════════════════
    IF v_formula IS NOT NULL AND length(trim(v_formula)) > 0 THEN
        v_replaced_formula := v_formula;

        -- Replace all variable tokens {token_name} with their numeric or boolean values from pricing_inputs
        FOR v_token IN SELECT DISTINCT (regexp_matches(v_formula, '\{([a-zA-Z0-9_]+)\}', 'g'))[1] LOOP
            v_token_val := v_pricing_inputs -> v_token;
            IF v_token_val IS NULL THEN
                v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
            ELSIF jsonb_typeof(v_token_val) = 'boolean' THEN
                IF (v_token_val)::BOOLEAN THEN
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '1.0');
                ELSE
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
                END IF;
            ELSIF jsonb_typeof(v_token_val) = 'number' THEN
                DECLARE
                    v_val_num NUMERIC := (v_token_val)::NUMERIC;
                    v_field_cfg JSONB;
                    v_min NUMERIC;
                BEGIN
                    -- Check if there is a field config in v_fields for this token
                    IF v_fields IS NOT NULL THEN
                        SELECT f INTO v_field_cfg 
                        FROM jsonb_array_elements(v_fields) AS f 
                        WHERE f ->> 'id' = v_token;
                        
                        IF v_field_cfg IS NOT NULL AND v_field_cfg ? 'min' THEN
                            v_min := (v_field_cfg ->> 'min')::NUMERIC;
                            IF v_val_num < v_min THEN
                                v_val_num := v_min;
                            END IF;
                        END IF;
                    END IF;

                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', v_val_num::TEXT);
                END;
            ELSE
                v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
            END IF;
        END LOOP;

        -- Security check: resulting expression may ONLY contain numbers, decimals, math operators, and parentheses
        IF v_replaced_formula ~ '^[0-9\.\+\-\*\/\(\)\s]+$' THEN
            v_eval_query := 'SELECT (' || v_replaced_formula || ')::NUMERIC;';
            BEGIN
                EXECUTE v_eval_query INTO v_base_price;
            EXCEPTION WHEN OTHERS THEN
                RAISE EXCEPTION 'خطأ في تقييم صيغة التسعير: %  |  الصيغة بعد الاستبدال: %', SQLERRM, v_replaced_formula USING ERRCODE = 'P0001';
            END;
        ELSE
            RAISE EXCEPTION 'صيغة التسعير غير آمنة أو تحتوي على رموز غير مسموح بها: %', v_replaced_formula USING ERRCODE = 'P0001';
        END IF;

        -- Generate execution trace entry for formula-based Stage 1
        v_trace_entry := jsonb_build_object(
            'stage', 'stage_1_base_pricing',
            'action', 'formula_evaluate',
            'formula', v_formula,
            'resolved_formula', v_replaced_formula,
            'before', 0.0,
            'after', v_base_price,
            'details', 'Calculated base price using formula-based engine.'
        );
        v_trace := v_trace || v_trace_entry;

        RETURN p_context || jsonb_build_object(
            'base_price', v_base_price,
            'subtotal', v_base_price,
            'extra_fees', v_extra_fees,
            'execution_trace', v_trace
        );
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- PATH B: DYNAMIC CONFIG-DRIVEN PRICING ENGINE (fields array defined)
    -- ══════════════════════════════════════════════════════════════════════
    IF v_fields IS NOT NULL AND jsonb_array_length(v_fields) > 0 THEN
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
            END IF;
        END LOOP;

        v_base_price := v_base_price * v_primary_val;

        v_trace_entry := jsonb_build_object(
            'stage', 'stage_1_base_pricing',
            'action', 'dynamic_evaluate',
            'before', v_unit_price,
            'after', v_base_price,
            'details', 'Calculated base price using dynamic config engine.'
        );
        v_trace := v_trace || v_trace_entry;

        RETURN p_context || jsonb_build_object(
            'base_price', v_base_price,
            'subtotal', v_base_price + v_extra_fees,
            'extra_fees', v_extra_fees,
            'execution_trace', v_trace
        );
    END IF;

    -- ══════════════════════════════════════════════════════════════════════
    -- PATH C: LEGACY FALLBACK PRICING PATH
    -- ══════════════════════════════════════════════════════════════════════
    IF v_method = 'fixed' OR v_method = 'per_issue' THEN
        v_base_price := v_unit_price;
    ELSIF v_method = 'per_square_meter' THEN
        v_area := COALESCE((v_pricing_inputs ->> 'area')::NUMERIC, 0.0);
        IF v_area > 0.0 THEN
            IF v_area < v_min_area THEN
                v_area := v_min_area;
            END IF;
            v_base_price := v_area * v_unit_price;
        END IF;
    ELSIF v_method = 'per_linear_meter' THEN
        -- Check if windows are provided in pricing inputs
        v_windows := v_pricing_inputs -> 'windows';
        IF v_windows IS NOT NULL AND jsonb_typeof(v_windows) = 'array' AND jsonb_array_length(v_windows) > 0 THEN
            -- Calculate total linear meters from windows
            v_total_linear := 0.0;
            DECLARE
                v_window JSONB;
                v_w NUMERIC;
                v_h NUMERIC;
                v_q INT;
                v_both BOOLEAN;
                v_w_linear NUMERIC;
            BEGIN
                FOR v_window IN SELECT * FROM jsonb_array_elements(v_windows) LOOP
                    v_w := (v_window ->> 'width')::NUMERIC;
                    v_h := (v_window ->> 'height')::NUMERIC;
                    v_q := COALESCE((v_window ->> 'quantity')::INT, 1);
                    v_both := COALESCE((v_window ->> 'is_both_sides')::BOOLEAN, false);
                    
                    v_w_linear := (v_w + v_h) * 2.0;
                    IF v_both THEN
                        v_w_linear := v_w_linear * 2.0;
                    END IF;
                    v_total_linear := v_total_linear + (v_w_linear * v_q);
                END LOOP;
            END;
        ELSE
            v_total_linear := COALESCE((v_pricing_inputs ->> 'total_linear_meters')::NUMERIC, 0.0);
        END IF;
        
        v_base_price := v_total_linear * v_unit_price;
    END IF;

    v_trace_entry := jsonb_build_object(
        'stage', 'stage_1_base_pricing',
        'action', 'legacy_evaluate',
        'before', v_unit_price,
        'after', v_base_price,
        'details', 'Calculated base price using legacy fallback path.'
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

COMMIT;
