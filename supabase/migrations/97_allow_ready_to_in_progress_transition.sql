-- ==============================================================================
-- Migration 97: Allow direct state transition from 'ready' to 'in_progress'
-- Description: Streamlines technician workflow by removing redundant intermediate
--              steps (on_the_way, arrived) and allowing direct start of service.
-- ==============================================================================

BEGIN;

INSERT INTO public.state_transitions (from_status, to_status, allowed_role, condition_code)
VALUES
    ('ready'::public.order_status_v2, 'in_progress'::public.order_status_v2, 'technician', NULL),
    ('ready'::public.order_status_v2, 'in_progress'::public.order_status_v2, 'admin', NULL)
ON CONFLICT (from_status, to_status, allowed_role) DO NOTHING;

COMMIT;
