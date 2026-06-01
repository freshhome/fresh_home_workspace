-- ==============================================================================
-- Fresh Home: Lifecycle Engine Refactor (v2.0 — Production Stabilization)
-- File: 16_lifecycle_engine_refactor.sql
--
-- STEP 2.1 — Lifecycle Engine Refactor
-- This migration REPLACES and HARDENS the lifecycle engine by:
--   A. Standardizing all enums to public.order_status_v2
--   B. Refactoring create_atomic_booking to pass through transition_booking
--   C. Adding missing state transitions (ready, pending→assigned)
--   D. Fixing process_auto_accept_bookings enum reference
--   E. Scheduling previously orphaned cron jobs
--   F. Hardening the v_pending_notifications view
-- ==============================================================================

-- ==============================================================================
-- TASK A — Enum Standardization
-- Verify order_status_v2 has all required values. Add missing ones if needed.
-- ==============================================================================

DO $$
BEGIN
    -- Add 'ready' if missing (technician attendance confirmation state)
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumtypid = 'public.order_status_v2'::regtype 
          AND enumlabel = 'ready'
    ) THEN
        ALTER TYPE public.order_status_v2 ADD VALUE IF NOT EXISTS 'ready' AFTER 'accepted';
        RAISE NOTICE 'Added: ready to order_status_v2';
    END IF;

    -- Add 'pending' if missing (awaiting reassignment after rejection)
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumtypid = 'public.order_status_v2'::regtype 
          AND enumlabel = 'pending'
    ) THEN
        ALTER TYPE public.order_status_v2 ADD VALUE IF NOT EXISTS 'pending' BEFORE 'assigned';
        RAISE NOTICE 'Added: pending to order_status_v2';
    END IF;

    -- Add 'created' if missing (initial insertion state)
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumtypid = 'public.order_status_v2'::regtype 
          AND enumlabel = 'created'
    ) THEN
        ALTER TYPE public.order_status_v2 ADD VALUE IF NOT EXISTS 'created' BEFORE 'pending';
        RAISE NOTICE 'Added: created to order_status_v2';
    END IF;
END $$;

-- ==============================================================================
-- TASK C — State Transition Integrity
-- Add all missing transitions required by Flutter + technician workflow.
-- ==============================================================================

-- Add transitions that were missing or inconsistent
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, condition_code)
VALUES
    -- 1. Technician attendance confirmation (accepted → ready)
    ('accepted',  'ready',      'technician', 'CHECK_ATTENDANCE'),
    -- 2. Reinstate after technician rejection (pending → assigned by admin)
    ('pending',   'assigned',   'admin',       NULL),
    -- 3. Technician moves after attendance confirmed (ready → on_the_way)
    ('ready',     'on_the_way', 'technician',  NULL),
    -- 4. Initial booking creation (created → assigned by admin/system)
    ('created',   'assigned',   'admin',       NULL),
    ('created',   'assigned',   'system',      NULL),
    -- 5. Customer cancellation from ready state
    ('ready',     'cancelled',  'customer',    NULL),
    -- 6. System auto-expire of unassigned bookings
    ('created',   'expired',    'system',      NULL)
ON CONFLICT (from_status, to_status, allowed_role) DO NOTHING;

-- Verify no dead-end states (informational — check manually)
-- Terminal states by design: completed, cancelled, expired, failed_no_show
-- All other states must have at least one forward transition.

-- ==============================================================================
-- TASK D — Fix process_auto_accept_bookings (Enum Bug Fix)
-- Was using ::order_status (old), now uses ::public.order_status_v2
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.process_auto_accept_bookings()
RETURNS VOID AS $$
DECLARE
    v_record RECORD;
BEGIN
    FOR v_record IN (
        SELECT id, user_id, technician_id, readable_id, status
        FROM public.bookings
        WHERE status = 'assigned'::public.order_status_v2  -- ← FIXED: was ::order_status
          AND assigned_at < (NOW() - INTERVAL '2 hours')
    ) LOOP
        -- Use the official lifecycle gatekeeper — not a direct UPDATE
        PERFORM public.transition_booking(
            v_record.id,
            'accepted'::public.order_status_v2,  -- ← FIXED: was ::order_status
            v_record.technician_id,
            'technician',
            'SYSTEM_AUTO_ACCEPT',
            'تم القبول التلقائي بواسطة النظام بعد مرور ساعتين من التعيين.'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- TASK B — Refactor create_atomic_booking
-- BEFORE: INSERT directly as 'assigned' (bypasses State Machine)
-- AFTER:  INSERT as 'created', then call transition_booking → 'assigned'
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id          UUID,
    p_sub_service_id   UUID,
    p_technician_id    UUID,
    p_scheduled_day    DATE,
    p_address_snapshot JSONB,
    p_service_snapshot JSONB,
    p_price_snapshot   JSONB,
    p_contact_name     TEXT DEFAULT 'Client',
    p_contact_phones   TEXT[] DEFAULT '{}'::TEXT[],
    p_start_time_slot  TIME DEFAULT '09:00',
    p_actor_id         UUID DEFAULT NULL,    -- Admin or System ID performing the assignment
    p_actor_role       TEXT DEFAULT 'admin'  -- Role performing the assignment
) RETURNS UUID AS $$
DECLARE
    v_tech_id      UUID;
    v_booking_id   UUID;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- A. Resolve technician (auto-assign if not specified)
    IF p_technician_id IS NULL THEN
        SELECT technician_id INTO v_tech_id
        FROM public.get_available_technicians(p_sub_service_id, p_scheduled_day)
        LIMIT 1;

        IF v_tech_id IS NULL THEN
            RAISE EXCEPTION 'لا يوجد فني متاح لهذا اليوم' USING ERRCODE = 'P0002';
        END IF;
    ELSE
        v_tech_id := p_technician_id;
    END IF;

    -- B. Advisory Lock: prevent double-booking for same technician/day
    v_lock_key_1 := hashtext(v_tech_id::TEXT);
    v_lock_key_2 := hashtext(p_scheduled_day::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    -- C. Insert booking in 'created' state (State Machine Entry Point)
    -- No status bypass. No direct assignment. Clean entry.
    INSERT INTO public.bookings (
        user_id, technician_id, service_id, scheduled_day, start_time_slot,
        address_snapshot, service_snapshot, price_snapshot,
        contact_name, contact_phones,
        status  -- 'created' is the ONLY valid initial state
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, p_price_snapshot,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2
    ) RETURNING id INTO v_booking_id;

    -- D. Immediately transition to 'assigned' through the official gatekeeper
    -- This ensures:
    --   1. Audit event is logged in booking_events
    --   2. Notification is enqueued in notifications_outbox
    --   3. assigned_at timestamp is set correctly
    --   4. State Machine transition rules are enforced
    PERFORM public.transition_booking(
        v_booking_id,
        'assigned'::public.order_status_v2,
        COALESCE(p_actor_id, p_user_id),  -- Fallback to user_id if admin_id not provided
        p_actor_role,
        'BOOKING_CREATION',
        'تم إنشاء الحجز وتعيينه للفني.'
    );

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- ==============================================================================
-- TASK D — Lifecycle Integrity: Fix check_operational_no_shows
-- Was using 'system' as actor_role but no system UUID — protect booking_events
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.check_operational_no_shows()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN
        SELECT id FROM public.bookings
        WHERE status IN ('accepted'::public.order_status_v2, 'on_the_way'::public.order_status_v2)
          AND (scheduled_day + start_time_slot + INTERVAL '2 hours') < NOW()
    LOOP
        BEGIN
            PERFORM public.transition_booking(
                v_rec.id,
                'failed_no_show'::public.order_status_v2,
                NULL::UUID,   -- System has no user ID
                'system',
                'SYSTEM_TIMEOUT',
                'لم يصل الفني خلال ساعتين من الموعد المحدد.'
            );
        EXCEPTION WHEN OTHERS THEN
            -- Log failure but continue processing other bookings
            RAISE WARNING 'check_operational_no_shows failed for booking %: %', v_rec.id, SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- TASK D — Lifecycle Integrity: Fix check_assignment_expiry
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.check_assignment_expiry()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN
        SELECT id FROM public.bookings
        WHERE status = 'assigned'::public.order_status_v2
          AND assigned_at < (NOW() - INTERVAL '4 hours')
    LOOP
        BEGIN
            PERFORM public.transition_booking(
                v_rec.id,
                'expired'::public.order_status_v2,
                NULL::UUID,
                'system',
                'SYSTEM_TIMEOUT',
                'انتهت صلاحية التعيين بعد 4 ساعات بدون استجابة.'
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'check_assignment_expiry failed for booking %: %', v_rec.id, SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- TASK E — Schedule Previously Orphaned Cron Jobs
-- These functions existed but had no cron.schedule() calls
-- ==============================================================================

-- Remove any previous duplicate schedules first
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname IN ('fresh-home-assignment-expiry', 'fresh-home-no-show-check', 'fresh-home-auto-accept');

-- Schedule assignment expiry check (every hour)
SELECT cron.schedule(
    'fresh-home-assignment-expiry',
    '0 * * * *',
    $$ SELECT public.check_assignment_expiry(); $$
);

-- Schedule no-show detection (every 30 minutes)
SELECT cron.schedule(
    'fresh-home-no-show-check',
    '*/30 * * * *',
    $$ SELECT public.check_operational_no_shows(); $$
);

-- Schedule auto-accept (every 15 minutes)
SELECT cron.schedule(
    'fresh-home-auto-accept',
    '*/15 * * * *',
    $$ SELECT public.process_auto_accept_bookings(); $$
);

-- ==============================================================================
-- TASK F — Harden v_pending_notifications View
-- BEFORE: Missing retry_count and status columns (caused Edge Function errors)
-- AFTER:  All columns needed by the worker are present
-- NOTE:   Must DROP first — PostgreSQL forbids column renames via CREATE OR REPLACE
-- ==============================================================================

DROP VIEW IF EXISTS public.v_pending_notifications;

CREATE VIEW public.v_pending_notifications AS
SELECT
    n.id             AS outbox_id,
    n.recipient_id,
    n.recipient_type,
    n.event_type,
    n.title,
    n.body,
    n.data,
    n.status,          -- Required: for Edge Function to verify state
    n.retry_count,     -- Required: for retry logic in Edge Function
    t.fcm_token,
    t.platform,
    t.device_id
FROM public.notifications_outbox n
JOIN public.user_fcm_tokens t ON n.recipient_id = t.user_id
WHERE n.status = 'pending'
  AND n.retry_count < 5
  AND n.recipient_id IS NOT NULL;  -- Exclude system-wide alerts with NULL recipient

COMMENT ON VIEW public.v_pending_notifications IS
'Production-hardened view for Edge Function worker. Includes all fields required for FCM delivery and retry logic. Excludes NULL-recipient system alerts.';

-- ==============================================================================
-- TASK E — Also add 'system' as allowed role in transition_booking
-- The current gatekeeper rejects 'system' role since it only validates against
-- state_transitions.allowed_role values
-- ==============================================================================

-- Add system-originated transitions
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, condition_code)
VALUES
    ('assigned',    'expired',        'system', NULL),
    ('accepted',    'failed_no_show', 'system', NULL),
    ('on_the_way',  'failed_no_show', 'system', NULL),
    ('assigned',    'accepted',       'system', NULL)  -- Auto-accept
ON CONFLICT (from_status, to_status, allowed_role) DO NOTHING;

-- ==============================================================================
-- VALIDATION REPORT
-- Run this after migration to verify all transitions are correctly seeded
-- ==============================================================================

-- To verify the final transition matrix, execute:
-- SELECT from_status, to_status, allowed_role, condition_code, is_active
-- FROM public.state_transitions
-- ORDER BY from_status, to_status, allowed_role;
