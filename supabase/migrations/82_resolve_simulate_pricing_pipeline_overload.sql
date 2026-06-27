-- ==============================================================================
-- Fresh Home: Resolve simulate_pricing_pipeline Function Overloading (PGRST203)
-- Migration ID: 82_resolve_simulate_pricing_pipeline_overload
-- Description: Drop the deprecated UUID overload of simulate_pricing_pipeline
--              to resolve ambiguity for PostgREST.
-- ==============================================================================

BEGIN;

-- 1. Drop the legacy UUID-based simulation function
DROP FUNCTION IF EXISTS public.simulate_pricing_pipeline(
    UUID,   -- p_sub_service_id
    JSONB,  -- p_price_config
    JSONB,  -- p_rules
    JSONB,  -- p_discounts
    JSONB   -- p_pricing_inputs
) CASCADE;

COMMIT;
