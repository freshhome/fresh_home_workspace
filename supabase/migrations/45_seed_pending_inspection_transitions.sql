-- ==============================================================================
-- Fresh Home: Seed state transitions for pending_inspection
-- Migration ID: 45_seed_pending_inspection_transitions
-- ==============================================================================

BEGIN;

-- ── SEED STATE TRANSITIONS FOR PENDING_INSPECTION ────────────────────────────
-- These rows define who can transition bookings into and out of pending_inspection
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, is_active, condition_code)
VALUES
    -- 1. A client or admin can place a booking directly into pending_inspection upon creation
    ('created'::public.order_status_v2, 'pending_inspection'::public.order_status_v2, 'customer', true, null),
    ('created'::public.order_status_v2, 'pending_inspection'::public.order_status_v2, 'admin', true, null),
    
    -- 2. Admin can assign a technician for the on-site inspection
    ('pending_inspection'::public.order_status_v2, 'assigned'::public.order_status_v2, 'admin', true, null),
    
    -- 3. A technician or admin on-site can place a booking into pending_inspection (if it needs new quote approval)
    ('arrived'::public.order_status_v2, 'pending_inspection'::public.order_status_v2, 'technician', true, null),
    ('arrived'::public.order_status_v2, 'pending_inspection'::public.order_status_v2, 'admin', true, null),
    
    -- 4. Once inspection is complete and price is set, the technician or admin can start the service
    ('pending_inspection'::public.order_status_v2, 'in_progress'::public.order_status_v2, 'technician', true, null),
    ('pending_inspection'::public.order_status_v2, 'in_progress'::public.order_status_v2, 'admin', true, null),
    
    -- 5. A pending_inspection booking can be cancelled by the customer or admin
    ('pending_inspection'::public.order_status_v2, 'cancelled'::public.order_status_v2, 'customer', true, null),
    ('pending_inspection'::public.order_status_v2, 'cancelled'::public.order_status_v2, 'admin', true, null)
ON CONFLICT (from_status, to_status, allowed_role) DO UPDATE
SET is_active = EXCLUDED.is_active,
    condition_code = EXCLUDED.condition_code;

COMMIT;
