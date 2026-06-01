-- ==============================================================================
-- Fresh Home: Formula-Based Pricing Engine
-- Migration ID: 43_add_formula_pricing
-- Description: 
--   Phase 3 of the Dynamic Pricing System Evolution.
--   Adds support for a `base_price_formula` text field inside price_config JSONB.
--   When present, stage_1_calculate_base_pricing evaluates the formula dynamically
--   using secure token replacement and regex sanitization (same pattern as Phase 2).
--   Backward compatibility is preserved: existing services without a formula
--   continue to work with hardcoded enum logic (fixed, per_square_meter, etc.).
-- ==============================================================================

BEGIN;

-- ============================================================================
-- 1. Update validate_price_config to allow optional base_price_formula field
-- ============================================================================
-- Drop the existing constraint so we can redefine the validation function
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS chk_services_price_config;

-- Redefine the validation function to also allow base_price_formula as optional string
CREATE OR REPLACE FUNCTION public.validate_price_config(p_config JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    v_type TEXT;
    v_base_val NUMERIC;
    v_fields JSONB;
    v_field JSONB;
    v_options JSONB;
    v_opt JSONB;
    v_formula TEXT;
BEGIN
    -- Handle SQL NULL and JSONB 'null' literal
    IF p_config IS NULL OR jsonb_typeof(p_config) = 'null' THEN
        RETURN TRUE;
    END IF;

    -- Config must be a JSON object
    IF jsonb_typeof(p_config) != 'object' THEN
        RETURN FALSE;
    END IF;

    -- BACKWARD COMPATIBILITY GUARD:
    IF NOT (p_config ? 'fields') THEN
        RETURN TRUE;
    END IF;

    v_type := p_config ->> 'type';
    IF v_type IS NULL OR v_type NOT IN ('fixed', 'per_square_meter', 'per_linear_meter', 'per_issue', 'unknown') THEN
        RETURN FALSE;
    END IF;

    v_base_val := COALESCE((p_config ->> 'value')::NUMERIC, (p_config ->> 'base_price_value')::NUMERIC);
    IF v_base_val IS NULL OR v_base_val < 0 THEN
        RETURN FALSE;
    END IF;

    v_fields := p_config -> 'fields';
    IF v_fields IS NOT NULL THEN
        IF jsonb_typeof(v_fields) != 'array' THEN
            RETURN FALSE;
        END IF;

        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            IF v_field ->> 'id' IS NULL OR v_field ->> 'type' IS NULL THEN
                RETURN FALSE;
            END IF;

            IF v_field ->> 'type' NOT IN ('number', 'toggle', 'dropdown', 'text', 'multi-select') THEN
                RETURN FALSE;
            END IF;

            IF v_field -> 'label' IS NULL OR jsonb_typeof(v_field -> 'label') != 'object' THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;

    v_options := p_config -> 'options';
    IF v_options IS NOT NULL THEN
        IF jsonb_typeof(v_options) != 'array' THEN
            RETURN FALSE;
        END IF;

        FOR v_opt IN SELECT * FROM jsonb_array_elements(v_options) LOOP
            IF v_opt ->> 'key' IS NULL OR COALESCE((v_opt ->> 'value')::NUMERIC, 0) < 0 THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;

    -- Validate base_price_formula if present: must be a non-empty string
    IF p_config ? 'base_price_formula' THEN
        v_formula := p_config ->> 'base_price_formula';
        IF v_formula IS NULL OR length(trim(v_formula)) = 0 THEN
            RETURN FALSE;
        END IF;
        -- Formula can reference variable tokens like {area}, {width}, etc.
        -- We only validate that it's a non-empty string here; runtime evaluation
        -- happens inside stage_1_calculate_base_pricing with full regex safety.
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply the constraint using the updated validation function
ALTER TABLE public.services
ADD CONSTRAINT chk_services_price_config
CHECK (price_config IS NULL OR jsonb_typeof(price_config) = 'null' OR public.validate_price_config(price_config));

-- ============================================================================
-- 2. Update stage_1_calculate_base_pricing to support base_price_formula
-- ============================================================================
DROP FUNCTION IF EXISTS public.stage_1_calculate_base_pricing(TEXT, JSONB, JSONB) CASCADE;

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

        -- Replace all variable tokens {token_name} with their numeric values from pricing_inputs
        FOR v_token IN SELECT DISTINCT (regexp_matches(v_formula, '\{([a-zA-Z0-9_]+)\}', 'g'))[1] LOOP
            v_token_val := v_pricing_inputs -> v_token;
            IF v_token_val IS NULL OR jsonb_typeof(v_token_val) != 'number' THEN
                -- Token not found or not numeric → replace with 0.0 safely
                v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
            ELSE
                v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', (v_token_val)::TEXT);
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

    -- ══════════════════════════════════════════════════════════════════════
    -- PATH C: CLASSIC / LEGACY FALLBACK PRICING
    -- ══════════════════════════════════════════════════════════════════════
    ELSE
        IF v_method = 'per_square_meter' THEN
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
            v_base_price := v_unit_price;
        ELSE
            RAISE EXCEPTION 'طريقة التسعير (%) غير مدعومة معمارياً حالياً', v_method USING ERRCODE = 'P0003';
        END IF;
    END IF;

    -- Generate execution trace entry for Stage 1 (classic/dynamic paths)
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

COMMIT;
