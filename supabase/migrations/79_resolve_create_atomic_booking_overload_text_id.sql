-- Migration ID: 79_resolve_create_atomic_booking_overload_text_id
-- Description: Drop obsolete 12-parameter create_atomic_booking signature that has p_sub_service_id as TEXT to resolve RPC overload conflict.

BEGIN;

-- Drop the old 12-parameter TEXT-based create_atomic_booking signature to avoid overloading conflicts
DROP FUNCTION IF EXISTS public.create_atomic_booking(
    p_user_id                UUID,
    p_sub_service_id         TEXT,
    p_technician_id          UUID,
    p_scheduled_day          DATE,
    p_address_snapshot       JSONB,
    p_service_snapshot       JSONB,
    p_pricing_inputs         JSONB,
    p_contact_name           TEXT,
    p_contact_phones         TEXT[],
    p_start_time_slot        TIME,
    p_actor_id               UUID,
    p_actor_role             TEXT
) CASCADE;

-- Also proactively drop any other legacy UUID-based 12-parameter variations if they exist
DROP FUNCTION IF EXISTS public.create_atomic_booking(
    p_user_id                UUID,
    p_sub_service_id         UUID,
    p_technician_id          UUID,
    p_scheduled_day          DATE,
    p_address_snapshot       JSONB,
    p_service_snapshot       JSONB,
    p_pricing_inputs         JSONB,
    p_contact_name           TEXT,
    p_contact_phones         TEXT[],
    p_start_time_slot        TIME,
    p_actor_id               UUID,
    p_actor_role             TEXT
) CASCADE;

COMMIT;
