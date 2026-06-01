-- ==============================================================================
-- Fresh Home: Add pending_inspection status to enum
-- Migration ID: 44_add_pending_inspection_status
-- ==============================================================================

ALTER TYPE public.order_status_v2 ADD VALUE IF NOT EXISTS 'pending_inspection';
