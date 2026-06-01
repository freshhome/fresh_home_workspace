-- ==============================================================================
-- Fresh Home: Booking Logic (Refactored)
-- Description: Core booking functions. Legacy version consolidated to v3.0 logic.
-- ==============================================================================

-- This file is now primarily a redirection/stub for core logic.
-- Legacy create_atomic_booking (TIMESTAMPTZ version) is DROPPED to ensure v3.0 takes priority.

DROP FUNCTION IF EXISTS public.get_available_days(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, TIMESTAMPTZ, JSONB, JSONB, JSONB, TEXT);
