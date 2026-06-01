-- ==============================================================================
-- Fresh Home: Fix Function Overload Conflict
-- File: 21_fix_create_atomic_booking_overload.sql
--
-- PROBLEM: Two versions of create_atomic_booking exist in the database:
--   1. OLD (10 params) — from 01_booking_logic.sql
--   2. NEW (12 params) — from 16_lifecycle_engine_refactor.sql
--
-- PostgREST (PGRST203) cannot choose between them when Flutter sends 10 params.
--
-- SOLUTION: Drop the old 10-param version.
-- The new 12-param version has DEFAULT values for p_actor_id and p_actor_role,
-- so it works perfectly when called with only 10 params (backwards compatible).
-- ==============================================================================

-- Drop the OLD 10-param version (no p_actor_id, no p_actor_role)
DROP FUNCTION IF EXISTS public.create_atomic_booking(
    UUID,   -- p_user_id
    UUID,   -- p_sub_service_id
    UUID,   -- p_technician_id
    DATE,   -- p_scheduled_day
    JSONB,  -- p_address_snapshot
    JSONB,  -- p_service_snapshot
    JSONB,  -- p_price_snapshot
    TEXT,   -- p_contact_name
    TEXT[], -- p_contact_phones
    TIME    -- p_start_time_slot
);

-- Verify only ONE version remains
SELECT
    p.proname                               AS function_name,
    pg_get_function_arguments(p.oid)        AS arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'create_atomic_booking';

-- Expected result: exactly 1 row with 12 params (including p_actor_id, p_actor_role)
