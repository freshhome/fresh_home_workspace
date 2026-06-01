-- ==============================================================================
-- Fresh Home: Fix JSONB Null Check Constraints
-- Migration ID: 35_fix_jsonb_null
-- Description: Handle both SQL NULL and JSONB 'null' literal values for price_config
-- in the check constraints and validation function.
-- ==============================================================================

BEGIN;

-- 1. Drop existing constraints
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS chk_bookable_fields;
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS chk_services_price_config;

-- 2. Re-create chk_bookable_fields to support both SQL NULL and JSONB 'null'
ALTER TABLE public.services ADD CONSTRAINT chk_bookable_fields
CHECK (
    (is_bookable = true AND price_config IS NOT NULL AND jsonb_typeof(price_config) != 'null') OR
    (is_bookable = false AND (price_config IS NULL OR jsonb_typeof(price_config) = 'null'))
);

-- 3. Update the validation function to correctly return true for SQL NULL or JSONB 'null',
-- and allow 'unknown' pricing method (used as default for newly created services).
CREATE OR REPLACE FUNCTION public.validate_price_config(p_config JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    v_type TEXT;
    v_base_val NUMERIC;
    v_fields JSONB;
    v_field JSONB;
    v_options JSONB;
    v_opt JSONB;
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
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-create chk_services_price_config constraint supporting SQL NULL and JSONB 'null'
ALTER TABLE public.services 
ADD CONSTRAINT chk_services_price_config 
CHECK (price_config IS NULL OR jsonb_typeof(price_config) = 'null' OR public.validate_price_config(price_config));

COMMIT;
