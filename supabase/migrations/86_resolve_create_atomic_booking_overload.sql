-- ==============================================================================
-- Fresh Home: Resolve create_atomic_booking Function Overloading (PGRST203)
-- Migration ID: 86_resolve_create_atomic_booking_overload
-- Description: Drop the deprecated 12-parameter UUID overload of create_atomic_booking
--              to resolve ambiguity for PostgREST when executing bookings.
-- ==============================================================================

BEGIN;

-- Drop the legacy UUID-based 12-parameter create_atomic_booking function
DROP FUNCTION IF EXISTS public.create_atomic_booking(
    UUID,   -- p_user_id
    UUID,   -- p_sub_service_id
    UUID,   -- p_technician_id
    DATE,   -- p_scheduled_day
    JSONB,  -- p_address_snapshot
    JSONB,  -- p_service_snapshot
    JSONB,  -- p_pricing_inputs
    TEXT,   -- p_contact_name
    TEXT[], -- p_contact_phones
    TIME WITHOUT TIME ZONE, -- p_start_time_slot
    UUID,   -- p_actor_id
    TEXT    -- p_actor_role
) CASCADE;

COMMIT;
