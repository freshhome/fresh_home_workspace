-- ==============================================================================
-- Fresh Home: Resolve create_atomic_booking function overload conflict
-- Migration ID: 59_resolve_create_atomic_booking_overload
--
-- PROBLEM: The remote database has two versions of public.create_atomic_booking:
--   1. Old (p_sub_service_id is UUID) - 12 parameters
--   2. New (p_sub_service_id is TEXT) - 12 parameters
--
-- PostgREST fails with PGRST203 (Multiple Choices) when calling this RPC because
-- it cannot distinguish between them.
--
-- SOLUTION: Drop the old UUID-based version.
-- ==============================================================================

BEGIN;

-- Drop the legacy 12-param UUID-based version
DROP FUNCTION IF EXISTS public.create_atomic_booking(
    UUID,   -- p_user_id
    UUID,   -- p_sub_service_id (legacy UUID type)
    UUID,   -- p_technician_id
    DATE,   -- p_scheduled_day
    JSONB,  -- p_address_snapshot
    JSONB,  -- p_service_snapshot
    JSONB,  -- p_pricing_inputs
    TEXT,   -- p_contact_name
    TEXT[], -- p_contact_phones
    TIME,   -- p_start_time_slot
    UUID,   -- p_actor_id
    TEXT    -- p_actor_role
) CASCADE;

-- Drop other potential legacy UUID-based overloads just in case
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME) CASCADE;
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT) CASCADE;

COMMIT;
