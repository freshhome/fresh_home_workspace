-- Migration ID: 96_technician_order_rejection_reassignment
-- Description: Allow transition from 'accepted' to 'pending' by 'technician'. Try to automatically reassign technician on rejection/apology.

BEGIN;

-- 1. Insert state transition for 'accepted' -> 'pending' by 'technician'
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, condition_code)
VALUES ('accepted'::public.order_status_v2, 'pending'::public.order_status_v2, 'technician', NULL)
ON CONFLICT (from_status, to_status, allowed_role) DO NOTHING;

-- 2. Redefine transition_booking function to handle technician rejection & auto-reassignment
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
    
    -- Variables for technician auto-reassignment
    v_old_tech_id UUID;
    v_service_id TEXT;
    v_scheduled_day DATE;
    v_new_tech_id UUID;
    v_is_available BOOLEAN := FALSE;
BEGIN
    -- Check if this is a trusted internal call
    v_trusted := COALESCE(NULLIF(current_setting('app.trusted_internal_call', true), ''), 'false') = 'true';

    -- Secure actor and role mapping
    IF auth.uid() IS NOT NULL AND NOT v_trusted THEN
        p_actor_id := auth.uid();
        
        SELECT r.name INTO v_db_role
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_actor_id
        ORDER BY CASE r.name
            WHEN 'admin' THEN 1
            WHEN 'technician' THEN 2
            WHEN 'client' THEN 3
            ELSE 4
        END ASC
        LIMIT 1;
        
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
    SELECT status, technician_id, service_id, scheduled_day 
    INTO v_old_status, v_old_tech_id, v_service_id, v_scheduled_day 
    FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
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

    -- Intercept technician rejection (transitioning to pending) to attempt auto-reassignment
    IF p_new_status = 'pending' AND p_actor_role = 'technician' THEN
        -- Loop through candidates, lock them, and check availability
        FOR v_new_tech_id IN 
            SELECT technician_id FROM public.get_available_technicians(v_service_id, v_scheduled_day)
            WHERE technician_id != v_old_tech_id
            ORDER BY rating DESC, current_load ASC
        LOOP
            -- Lock candidate + date
            PERFORM pg_advisory_xact_lock(hashtext(v_new_tech_id::TEXT), hashtext(v_scheduled_day::TEXT));
            
            -- Re-verify availability under lock
            SELECT EXISTS (
                SELECT 1 FROM public.get_available_technicians(v_service_id, v_scheduled_day)
                WHERE technician_id = v_new_tech_id
            ) INTO v_is_available;
            
            IF v_is_available THEN
                EXIT; -- Valid technician locked and found
            END IF;
        END LOOP;

        IF v_is_available AND v_new_tech_id IS NOT NULL THEN
            p_new_status := 'assigned';
        ELSE
            RAISE EXCEPTION 'NO_OTHER_TECHNICIAN_AVAILABLE' USING ERRCODE = 'P0003';
        END IF;
    END IF;

    -- 5. Atomic Update with Concurrency Guard
    UPDATE public.bookings
    SET 
        status = p_new_status,
        updated_at = NOW(),
        -- Logic for Technician Rejection / Reassignment
        technician_id = CASE 
            WHEN p_new_status = 'pending' THEN NULL 
            WHEN p_new_status = 'assigned' AND v_new_tech_id IS NOT NULL THEN v_new_tech_id
            ELSE technician_id 
        END,
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
            'metadata', p_metadata,
            'reassigned_from_technician_id', v_old_tech_id,
            'reassigned_to_technician_id', v_new_tech_id
        )
    );

    RETURN v_booking;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMIT;
