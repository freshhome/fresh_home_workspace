-- Migration ID: 102_support_linear_sectors_dynamic_field
-- Description: Enable dynamic 'linearSectors' field type in price_config, validate_pricing_inputs, and stage_1_calculate_base_pricing.

BEGIN;

-- 1. Redefine validate_price_config to allow linearSectors / linear_sectors / window_sectors
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
    IF v_type IS NULL OR v_type NOT IN ('fixed', 'per_square_meter', 'per_linear_meter', 'per_issue', 'unknown', 'inspection') THEN
        RETURN FALSE;
    END IF;

    v_base_val := COALESCE((p_config ->> 'value')::NUMERIC, (p_config ->> 'base_price_value')::NUMERIC);
    IF v_base_val IS NULL OR v_base_val < 0 THEN
        RETURN FALSE;
    END IF;

    v_fields := p_config -> 'fields';
    IF v_fields IS NOT NULL AND jsonb_typeof(v_fields) != 'null' THEN
        IF jsonb_typeof(v_fields) != 'array' THEN
            RETURN FALSE;
        END IF;

        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            IF v_field ->> 'id' IS NULL OR v_field ->> 'type' IS NULL THEN
                RETURN FALSE;
            END IF;

            IF v_field ->> 'type' NOT IN (
                'number', 'toggle', 'dropdown', 'text', 'multi-select', 
                'optionsGroup', 'options_group', 
                'linearSectors', 'linear_sectors', 'window_sectors', 'windowSectors'
            ) THEN
                RETURN FALSE;
            END IF;

            IF v_field -> 'label' IS NULL OR jsonb_typeof(v_field -> 'label') != 'object' THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;

    v_options := p_config -> 'options';
    IF v_options IS NOT NULL AND jsonb_typeof(v_options) != 'null' THEN
        IF jsonb_typeof(v_options) != 'array' THEN
            RETURN FALSE;
        END IF;

        FOR v_opt IN SELECT * FROM jsonb_array_elements(v_options) LOOP
            IF v_opt ->> 'key' IS NULL OR COALESCE((v_opt ->> 'value')::NUMERIC, 0) < 0 THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    END IF;

    -- Validate base_price_formula if present and not null: must be a non-empty string
    IF p_config ? 'base_price_formula' AND p_config ->> 'base_price_formula' IS NOT NULL THEN
        v_formula := p_config ->> 'base_price_formula';
        IF v_formula IS NULL OR length(trim(v_formula)) = 0 THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Ensure check constraint uses validate_price_config
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS check_service_price_config;
ALTER TABLE public.services ADD CONSTRAINT check_service_price_config
CHECK (price_config IS NULL OR jsonb_typeof(price_config) = 'null' OR public.validate_price_config(price_config));


-- 2. Update validate_pricing_inputs to support linearSectors
CREATE OR REPLACE FUNCTION public.validate_pricing_inputs(
    p_sub_service_id TEXT,
    p_pricing_inputs JSONB
) RETURNS VOID AS $$
DECLARE
    v_price_config JSONB;
    v_method TEXT;
    v_fields JSONB;
    v_field JSONB;
    v_field_id TEXT;
    v_field_type TEXT;
    v_required BOOLEAN;
    v_val JSONB;
BEGIN
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
            
            IF v_field_type IN ('linearSectors', 'linear_sectors', 'window_sectors', 'windowSectors') THEN
                IF v_required AND NOT (p_pricing_inputs ? 'windows') AND NOT (p_pricing_inputs ? 'total_linear_meters') AND NOT (p_pricing_inputs ? v_field_id) THEN
                    RAISE EXCEPTION 'أبعاد النوافذ أو الأطوال الخطية مطلوبة لحساب هذه الخدمة' USING ERRCODE = 'P0001';
                END IF;
                IF p_pricing_inputs ? 'windows' AND jsonb_typeof(p_pricing_inputs -> 'windows') != 'array' THEN
                    RAISE EXCEPTION 'بيانات النوافذ (windows) يجب أن تكون مصفوفة' USING ERRCODE = 'P0001';
                END IF;
            ELSE
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


-- 3. Update stage_1_calculate_base_pricing to support linearSectors calculation in Path B
CREATE OR REPLACE FUNCTION public.stage_1_calculate_base_pricing(
    p_context JSONB,
    p_price_config JSONB
) RETURNS JSONB AS $$
DECLARE
    v_pricing_inputs   JSONB;
    v_method           TEXT;
    v_unit_price       NUMERIC := 0.0;
    v_base_price       NUMERIC := 0.0;
    v_extra_fees       NUMERIC := 0.0;

    -- Legacy & Formula Variables
    v_area             NUMERIC := 0.0;
    v_min_area         NUMERIC := 1.0;
    v_windows          JSONB;
    v_total_linear     NUMERIC := 0.0;
    v_formula          TEXT;
    v_replaced_formula TEXT;
    v_token            TEXT;
    v_eval_query       TEXT;
    v_fields           JSONB;

    -- Dynamic config engine variables
    v_field            JSONB;
    v_field_id         TEXT;
    v_field_type       TEXT;
    v_field_val        NUMERIC;
    v_field_bool       BOOLEAN;
    v_modifier         NUMERIC;
    v_primary_val      NUMERIC := 1.0;
    v_has_linear_field BOOLEAN := false;

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

        FOR v_token IN SELECT DISTINCT (regexp_matches(v_formula, '\{([a-zA-Z0-9_]+)\}', 'g'))[1] LOOP
            DECLARE
                v_token_text TEXT := v_pricing_inputs ->> v_token;
            BEGIN
                IF v_token = 'base_price' THEN
                    IF v_token_text IS NULL THEN
                        v_token_text := v_unit_price::TEXT;
                    END IF;
                END IF;

                IF v_token_text IS NULL THEN
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
                ELSIF v_token_text = 'true' THEN
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '1.0');
                ELSIF v_token_text = 'false' THEN
                    v_replaced_formula := replace(v_replaced_formula, '{' || v_token || '}', '0.0');
                ELSIF v_token_text ~ '^-?[0-9]+(\.[0-9]+)?$' THEN
                    DECLARE
                        v_val_num NUMERIC := v_token_text::NUMERIC;
                        v_field_cfg JSONB;
                        v_min NUMERIC;
                    BEGIN
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
            END;
        END LOOP;

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

        -- Check if any field is linearSectors or if method is per_linear_meter
        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            v_field_id := v_field ->> 'id';
            v_field_type := v_field ->> 'type';

            IF v_field_type IN ('linearSectors', 'linear_sectors', 'window_sectors', 'windowSectors') 
               OR v_field_id IN ('windows', 'window_sectors') THEN
                v_has_linear_field := true;
            END IF;
        END LOOP;

        IF v_has_linear_field OR v_method = 'per_linear_meter' THEN
            v_windows := v_pricing_inputs -> 'windows';
            IF v_windows IS NOT NULL AND jsonb_typeof(v_windows) = 'array' AND jsonb_array_length(v_windows) > 0 THEN
                v_total_linear := 0.0;
                DECLARE
                    v_win JSONB;
                    v_w NUMERIC;
                    v_h NUMERIC;
                    v_q INT;
                    v_both BOOLEAN;
                    v_w_linear NUMERIC;
                BEGIN
                    FOR v_win IN SELECT * FROM jsonb_array_elements(v_windows) LOOP
                        v_w := (v_win ->> 'width')::NUMERIC;
                        v_h := (v_win ->> 'height')::NUMERIC;
                        v_q := COALESCE((v_win ->> 'quantity')::INT, 1);
                        v_both := COALESCE((v_win ->> 'is_both_sides')::BOOLEAN, false);
                        
                        v_w_linear := (v_w + v_h) * 2.0;
                        IF v_both THEN
                            v_w_linear := v_w_linear * 2.0;
                        END IF;
                        v_total_linear := v_total_linear + (v_w_linear * v_q);
                    END LOOP;
                END;
                v_primary_val := v_total_linear;
            ELSE
                v_primary_val := COALESCE((v_pricing_inputs ->> 'total_linear_meters')::NUMERIC, 1.0);
            END IF;
        END IF;

        -- Process other field modifiers (like additive or multiplicative options/toggles/numbers)
        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            v_field_id := v_field ->> 'id';
            v_field_type := v_field ->> 'type';

            IF v_pricing_inputs ? v_field_id THEN
                IF v_field_type = 'number' THEN
                    v_field_val := (v_pricing_inputs ->> v_field_id)::NUMERIC;
                    IF v_field_val IS NOT NULL THEN
                        IF v_field ? 'min' AND v_field_val < (v_field ->> 'min')::NUMERIC THEN
                            v_field_val := (v_field ->> 'min')::NUMERIC;
                        END IF;

                        IF v_field_id = 'area' AND NOT v_has_linear_field THEN
                            v_primary_val := v_field_val;
                        ELSIF v_field_id = 'total_linear_meters' AND NOT v_has_linear_field THEN
                            v_primary_val := v_field_val;
                        ELSE
                            IF v_field ? 'price_modifier' THEN
                                v_base_price := v_base_price + (v_field_val * (v_field ->> 'price_modifier')::NUMERIC);
                            END IF;
                        END IF;
                    END IF;
                ELSIF v_field_type = 'toggle' THEN
                    v_field_bool := (v_pricing_inputs -> v_field_id)::BOOLEAN;
                    IF v_field_bool IS TRUE AND v_field ? 'price_modifier' THEN
                        v_modifier := (v_field ->> 'price_modifier')::NUMERIC;
                        IF v_modifier > 5.0 THEN
                            v_extra_fees := v_extra_fees + v_modifier;
                        ELSE
                            v_base_price := v_base_price * v_modifier;
                        END IF;
                    END IF;
                ELSIF v_field_type = 'dropdown' THEN
                    -- If dropdown value matches an option that has a numeric price or modifier
                    DECLARE
                        v_sel_id TEXT := v_pricing_inputs ->> v_field_id;
                    BEGIN
                        IF v_sel_id ~ '^-?[0-9]+(\.[0-9]+)?$' THEN
                            v_extra_fees := v_extra_fees + v_sel_id::NUMERIC;
                        END IF;
                    END;
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
    -- PATH C: FALLBACK ENGINE (when fields array is empty/null)
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
        v_windows := v_pricing_inputs -> 'windows';
        IF v_windows IS NOT NULL AND jsonb_typeof(v_windows) = 'array' AND jsonb_array_length(v_windows) > 0 THEN
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
$$ LANGUAGE plpgsql STABLE;

-- 4. Update service FH-S-100012 to use dynamic field 'linearSectors'
UPDATE public.services
SET price_config = jsonb_build_object(
    'type', 'per_linear_meter',
    'base_price_value', 50.0,
    'unit', 'متر طولي',
    'min_price', 200.0,
    'fields', jsonb_build_array(
        jsonb_build_object(
            'id', 'window_sectors',
            'type', 'linearSectors',
            'label', jsonb_build_object('ar', 'أبعاد وقطاعات الألوميتال', 'en', 'Aluminum Window Sectors'),
            'unit', 'م.ط',
            'required', true,
            'description', jsonb_build_object('ar', 'حساب محيط الشبابيك والقطاعات بالمتر الطولي مع تحديد الوجهين أو وجه واحد', 'en', 'Window perimeter calculation in linear meters')
        )
    )
)
WHERE id = 'FH-S-100012';

COMMIT;
