-- ==============================================================================
-- Fresh Home: Lifecycle Management & Operational Controls (v1.0)
-- Description: Strict status transitions and failure detection logic.
-- ==============================================================================

-- 1. State Transitions Table
CREATE TABLE IF NOT EXISTS public.state_transitions (
    id             SERIAL PRIMARY KEY,
    from_status    public.order_status_v2 NOT NULL,
    to_status      public.order_status_v2 NOT NULL,
    allowed_role   TEXT NOT NULL,
    condition_code TEXT,
    is_active      BOOLEAN DEFAULT true,
    UNIQUE(from_status, to_status, allowed_role)
);

-- Seed Initial Transitions
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, condition_code)
VALUES 
('created',     'assigned',   'admin',      NULL),
('assigned',    'accepted',   'technician', NULL),
('assigned',    'pending',    'technician', NULL), -- Technician Rejection
('accepted',    'on_the_way', 'technician', 'CHECK_ATTENDANCE'),
('on_the_way',  'arrived',    'technician', 'CHECK_GPS'),
('arrived',     'in_progress','technician', 'CHECK_OTP'),
('in_progress', 'completed',  'technician', NULL),
-- Failure Cases
('on_the_way',  'failed',     'technician', NULL),
('arrived',     'failed',     'technician', NULL),
('in_progress', 'failed',     'technician', NULL),
-- Cancellation Rules
('created',     'cancelled',  'customer',   NULL),
('assigned',    'cancelled',  'customer',   NULL),
('accepted',    'cancelled',  'customer',   NULL)
ON CONFLICT DO NOTHING;

-- 2. Helper: Evaluate Transition Condition
CREATE OR REPLACE FUNCTION public.evaluate_transition_condition(
    p_condition_code TEXT,
    p_metadata       JSONB
) RETURNS BOOLEAN AS $$
BEGIN
    IF p_condition_code IS NULL THEN RETURN TRUE; END IF;

    CASE p_condition_code
        WHEN 'CHECK_GPS' THEN
            IF NOT (p_metadata ? 'location') THEN RETURN FALSE; END IF;
        WHEN 'CHECK_OTP' THEN
            IF (p_metadata->>'otp') IS NULL THEN RETURN FALSE; END IF;
        WHEN 'CHECK_ATTENDANCE' THEN
            -- In production, check real attendance table
            RETURN TRUE; 
        ELSE
            RETURN TRUE;
    END CASE;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql STABLE;

-- 3. transition_booking (The Master Gatekeeper v2.0)
-- Drop transition_booking with all potential argument signatures and schemas to avoid return type conflicts
DROP FUNCTION IF EXISTS public.transition_booking(uuid, public.order_status_v2, uuid, text, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.transition_booking(uuid, order_status_v2, uuid, text, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, public.order_status_v2, uuid, text, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, order_status_v2, uuid, text, text, text, jsonb) CASCADE;

-- Drop overloaded versions just in case
DROP FUNCTION IF EXISTS public.transition_booking(uuid, public.order_status_v2, uuid, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.transition_booking(uuid, order_status_v2, uuid, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, public.order_status_v2, uuid, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, order_status_v2, uuid, text, text, text, uuid) CASCADE;

DROP FUNCTION IF EXISTS public.transition_booking(uuid, public.order_status_v2, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.transition_booking(uuid, order_status_v2, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, public.order_status_v2, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, order_status_v2, uuid, text, text, text) CASCADE;
CREATE OR REPLACE FUNCTION public.transition_booking(
    p_booking_id    UUID,
    p_new_status    public.order_status_v2,
    p_actor_id      UUID,
    p_actor_role    TEXT,
    p_reason_code   TEXT DEFAULT NULL,
    p_notes         TEXT DEFAULT NULL,
    p_metadata      JSONB DEFAULT '{}'::JSONB
)
RETURNS public.bookings AS $$
DECLARE
    v_old_status public.order_status_v2;
    v_booking    public.bookings;
    v_cond_code  TEXT;
    v_is_valid   BOOLEAN := FALSE;
    v_force      BOOLEAN := COALESCE((p_metadata->>'force_override')::BOOLEAN, FALSE);
    v_trusted    BOOLEAN;
    v_db_role    TEXT;
BEGIN
    -- Check if this is a trusted internal call
    v_trusted := COALESCE(NULLIF(current_setting('app.trusted_internal_call', true), ''), 'false') = 'true';

    -- Secure actor and role mapping
    IF auth.uid() IS NOT NULL AND NOT v_trusted THEN
        p_actor_id := auth.uid();
        
        SELECT r.name INTO v_db_role
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_actor_id;
        
        IF v_db_role IS NULL THEN
            RAISE EXCEPTION 'Unauthorized: User role not configured.' USING ERRCODE = '42501';
        END IF;
        
        IF v_db_role = 'client' THEN
            p_actor_role := 'customer';
        ELSE
            p_actor_role := v_db_role;
        END IF;
    END IF;

    -- Administrative safety check: prevent standard users from spoofing admin roles
    IF p_actor_role = 'admin' AND NOT v_trusted AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Actor is not an administrator.' USING ERRCODE = '42501';
    END IF;

    -- 1. Fetch and Lock for safety (Race Condition Protection)
    SELECT status INTO v_old_status FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'BOOKING_NOT_FOUND'; END IF;

    -- 2. Idempotency
    IF v_old_status = p_new_status THEN 
        SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
        RETURN v_booking; 
    END IF;

    -- 3. Terminal State Check
    IF v_old_status IN ('completed', 'cancelled', 'expired', 'failed_no_show') AND NOT (p_actor_role = 'admin' AND v_force) THEN
        RAISE EXCEPTION 'TERMINAL_STATE_LOCKED';
    END IF;

    -- 4. Transition Validation
    IF p_actor_role = 'admin' AND v_force THEN
        IF p_reason_code IS NULL THEN RAISE EXCEPTION 'ADMIN_OVERRIDE_REQUIRES_REASON'; END IF;
        v_is_valid := TRUE;
    ELSE
        SELECT condition_code INTO v_cond_code
        FROM public.state_transitions
        WHERE from_status = v_old_status 
          AND to_status   = p_new_status 
          AND allowed_role = p_actor_role
          AND is_active   = true;
        
        IF v_cond_code IS NOT NULL OR FOUND THEN
            v_is_valid := public.evaluate_transition_condition(v_cond_code, p_metadata);
        END IF;
    END IF;

    IF NOT v_is_valid THEN
        RAISE EXCEPTION 'INVALID_TRANSITION' USING DETAIL = format('%s -> %s by %s', v_old_status, p_new_status, p_actor_role);
    END IF;

    -- 5. Atomic Update with Concurrency Guard
    UPDATE public.bookings
    SET 
        status = p_new_status,
        updated_at = NOW(),
        -- Logic for Technician Rejection / Reassignment
        technician_id = CASE WHEN p_new_status = 'pending' THEN NULL ELSE technician_id END,
        assigned_at   = CASE 
            WHEN p_new_status = 'assigned' THEN NOW() 
            WHEN p_new_status = 'pending'  THEN NULL 
            ELSE assigned_at 
        END,
        accepted_at   = CASE WHEN p_new_status = 'accepted'    THEN NOW() ELSE accepted_at END,
        dispatched_at = CASE WHEN p_new_status = 'on_the_way'  THEN NOW() ELSE dispatched_at END,
        arrived_at    = CASE WHEN p_new_status = 'arrived'     THEN NOW() ELSE arrived_at END,
        started_at    = CASE WHEN p_new_status = 'in_progress' THEN NOW() ELSE started_at END,
        completed_at  = CASE WHEN p_new_status = 'completed'   THEN NOW() ELSE completed_at END,
        cancelled_at  = CASE WHEN p_new_status = 'cancelled'   THEN NOW() ELSE cancelled_at END,
        cancellation_reason_code = COALESCE(p_reason_code, cancellation_reason_code),
        cancelled_by_role        = CASE WHEN p_new_status = 'cancelled' THEN p_actor_role ELSE cancelled_by_role END,
        is_critical   = FALSE,
        critical_reason = NULL
    WHERE id = p_booking_id AND status = v_old_status -- Strict Concurrency Guard
    RETURNING * INTO v_booking;

    IF NOT FOUND THEN RAISE EXCEPTION 'CONCURRENT_UPDATE_DETECTED'; END IF;

    -- 6. Audit Event Log
    INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
    VALUES (
        p_booking_id, 
        CASE WHEN v_force THEN 'FORCE_OVERRIDE' ELSE 'STATUS_CHANGE' END, 
        p_actor_id, 
        p_actor_role, 
        jsonb_build_object(
            'from', v_old_status, 
            'to', p_new_status, 
            'notes', p_notes, 
            'reason', p_reason_code,
            'metadata', p_metadata
        )
    );

    RETURN v_booking;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 2. check_operational_no_shows
CREATE OR REPLACE FUNCTION public.check_operational_no_shows()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN 
        SELECT id FROM public.bookings
        WHERE status IN ('accepted', 'on_the_way')
          AND (scheduled_day + start_time_slot + INTERVAL '2 hours') < NOW()
    LOOP
        PERFORM public.transition_booking(
            v_rec.id, 
            'failed_no_show'::order_status_v2, 
            NULL, 
            'system', 
            'SYSTEM_TIMEOUT', 
            'Technician did not arrive within 2 hours of scheduled time.'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. check_assignment_expiry
CREATE OR REPLACE FUNCTION public.check_assignment_expiry()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN 
        SELECT id FROM public.bookings
        WHERE status = 'assigned' 
          AND assigned_at < (NOW() - INTERVAL '4 hours')
    LOOP
        PERFORM public.transition_booking(
            v_rec.id, 
            'expired'::order_status_v2, 
            NULL, 
            'system', 
            'SYSTEM_TIMEOUT', 
            'Assignment expired after 4 hours without response.'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
