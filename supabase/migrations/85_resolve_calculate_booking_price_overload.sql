-- ==============================================================================
-- Fresh Home: Resolve calculate_booking_price Function Overloading (PGRST203)
-- Migration ID: 85_resolve_calculate_booking_price_overload
-- Description: Drop the deprecated UUID overload of calculate_booking_price
--              to resolve ambiguity for PostgREST when executing calculations.
-- ==============================================================================

BEGIN;

-- Drop the legacy UUID-based calculate_booking_price function
DROP FUNCTION IF EXISTS public.calculate_booking_price(
    UUID,   -- p_sub_service_id
    JSONB   -- p_pricing_inputs
) CASCADE;

COMMIT;
