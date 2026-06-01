-- ==============================================================================
-- Fresh Home: Fix calculate_booking_price Signature (TEXT ID Support)
-- Migration ID: 46_fix_calculate_booking_price_text_id
-- Description:
--   Phase 5 follow-up. Fixes the public RPC `calculate_booking_price` function
--   signature to accept TEXT for `p_sub_service_id` instead of UUID.
--   This ensures compatability with the text-based readable IDs (e.g., FH-S-100014)
--   sent by the mobile apps.
-- ==============================================================================

BEGIN;

-- 1. Drop the legacy UUID-based signature
DROP FUNCTION IF EXISTS public.calculate_booking_price(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.calculate_booking_price(TEXT, JSONB) CASCADE;

-- 2. Re-create the function with TEXT-based sub_service_id
CREATE OR REPLACE FUNCTION public.calculate_booking_price(
    p_sub_service_id TEXT,
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

COMMIT;
