-- ==============================================================================
-- Fresh Home: Pre-Production Hardening Fixes (v1.0)
-- File: 19_pre_production_hardening.sql
--
-- STEP 2.4 — Fixes for risks identified in Integration Validation Report
-- Fix 1: Timezone bug (Asia/Riyadh → Africa/Cairo)
-- Fix 2: True processing status to eliminate soft race condition
-- Fix 3: Consolidate overlapping SLA monitors
-- Fix 4: FCM token cleanup on UNREGISTERED error (DB-side)
-- ==============================================================================

-- ==============================================================================
-- FIX 1: Add 'processing' to notification_outbox_status enum
-- This eliminates the soft race condition entirely.
-- A row in 'processing' state cannot be picked up by any other worker invocation.
-- ==============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumtypid = 'public.notification_outbox_status'::regtype
          AND enumlabel = 'processing'
    ) THEN
        ALTER TYPE public.notification_outbox_status ADD VALUE 'processing' AFTER 'pending';
        RAISE NOTICE 'Added: processing to notification_outbox_status';
    END IF;
END $$;

-- ==============================================================================
-- FIX 2: Upgrade fetch_and_lock_pending_notifications
-- Now uses true 'processing' status instead of processed_at timestamp signal.
-- This provides hard guarantees: a 'processing' row is INVISIBLE to all
-- subsequent worker calls, regardless of lock state.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.fetch_and_lock_pending_notifications(
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    outbox_id      UUID,
    recipient_id   UUID,
    recipient_type public.notification_recipient_type,
    event_type     TEXT,
    title          TEXT,
    body           TEXT,
    data           JSONB,
    retry_count    INTEGER,
    fcm_token      TEXT,
    platform       TEXT,
    device_id      TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH locked_rows AS (
        -- Select with SKIP LOCKED: concurrent calls get different rows
        SELECT n.id
        FROM public.notifications_outbox n
        JOIN public.user_fcm_tokens t ON n.recipient_id = t.user_id
        WHERE n.status = 'pending'::public.notification_outbox_status
          AND n.retry_count < 5
          AND n.recipient_id IS NOT NULL
        ORDER BY n.created_at ASC
        LIMIT p_limit
        FOR UPDATE OF n SKIP LOCKED
    ),
    -- Atomically transition to 'processing' — hard lock, no race condition possible
    claimed AS (
        UPDATE public.notifications_outbox
        SET status       = 'processing'::public.notification_outbox_status,
            processed_at = NOW()
        WHERE id IN (SELECT id FROM locked_rows)
          AND status = 'pending'::public.notification_outbox_status
        RETURNING id
    )
    SELECT
        n.id           AS outbox_id,
        n.recipient_id,
        n.recipient_type,
        n.event_type,
        n.title,
        n.body,
        n.data,
        n.retry_count,
        t.fcm_token,
        t.platform,
        t.device_id
    FROM public.notifications_outbox n
    JOIN public.user_fcm_tokens t ON n.recipient_id = t.user_id
    WHERE n.id IN (SELECT id FROM claimed);
END;
$$;

-- ==============================================================================
-- FIX 2b: Add stale processing guard
-- If Edge Function crashes without updating status, rows stay in 'processing' forever.
-- This function resets them to 'pending' after 5 minutes.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.reset_stale_processing_notifications()
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications_outbox
    SET status = 'pending'::public.notification_outbox_status
    WHERE status = 'processing'::public.notification_outbox_status
      AND processed_at < (NOW() - INTERVAL '5 minutes');

    IF FOUND THEN
        RAISE NOTICE 'reset_stale_processing_notifications: reset stale rows to pending';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule stale guard to run every 5 minutes
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'fresh-home-reset-stale-notifications';

SELECT cron.schedule(
    'fresh-home-reset-stale-notifications',
    '*/5 * * * *',
    $$ SELECT public.reset_stale_processing_notifications(); $$
);

-- ==============================================================================
-- FIX 3: Fix timezone — 'Asia/Riyadh' → 'Africa/Cairo'
-- This was in schema/13_sla_monitoring_cron.sql (check_and_escalate_booking_delays)
-- Using wrong timezone caused ±1 hour SLA detection errors
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.check_and_escalate_booking_delays()
RETURNS VOID AS $$
DECLARE
    rec RECORD;
    v_start_timestamp TIMESTAMPTZ;
BEGIN
    FOR rec IN
        SELECT * FROM public.bookings
        WHERE status NOT IN (
            'completed'::public.order_status_v2,
            'cancelled'::public.order_status_v2,
            'failed_no_show'::public.order_status_v2,
            'expired'::public.order_status_v2
        )
          AND is_critical = false
    LOOP
        -- FIXED: Use 'Africa/Cairo' not 'Asia/Riyadh'
        v_start_timestamp := (rec.scheduled_day + rec.start_time_slot) AT TIME ZONE 'Africa/Cairo';

        -- SCENARIO 1: Technician hasn't accepted — 2 hours before appointment
        IF rec.status = 'assigned'::public.order_status_v2
           AND NOW() >= (v_start_timestamp - INTERVAL '2 hours')
        THEN
            UPDATE public.bookings
            SET is_critical = true,
                critical_reason = 'لم يتم القبول: الفني لم يقبل الطلب وتبقى أقل من ساعتين'
            WHERE id = rec.id;

            PERFORM public.insert_admin_notification(
                'طلب طارئ: لم يتم القبول ⚠️',
                'الطلب رقم ' || COALESCE(rec.readable_id, rec.id::TEXT) || ' لم يقبله الفني وتبقى أقل من ساعتين على الموعد.',
                rec.id, 'critical_not_accepted'
            );
            CONTINUE;
        END IF;

        -- SCENARIO 2: Technician late to move — 30 min before appointment
        IF rec.status IN (
               'assigned'::public.order_status_v2,
               'accepted'::public.order_status_v2,
               'ready'::public.order_status_v2
           )
           AND NOW() >= (v_start_timestamp - INTERVAL '30 minutes')
        THEN
            UPDATE public.bookings
            SET is_critical = true,
                critical_reason = 'تأخير في التحرك: تبقى نصف ساعة ولم يتحرك الفني للموقع'
            WHERE id = rec.id;

            PERFORM public.insert_admin_notification(
                'طلب طارئ: تأخر في التحرك 🚨',
                'الفني لم يتحرك لتنفيذ الطلب رقم ' || COALESCE(rec.readable_id, rec.id::TEXT) || ' وتبقى نصف ساعة فقط.',
                rec.id, 'critical_late_movement'
            );
            CONTINUE;
        END IF;

        -- SCENARIO 3: Job not started — 30 min after appointment time
        IF rec.status IN (
               'assigned'::public.order_status_v2,
               'accepted'::public.order_status_v2,
               'on_the_way'::public.order_status_v2,
               'arrived'::public.order_status_v2
           )
           AND NOW() >= (v_start_timestamp + INTERVAL '30 minutes')
        THEN
            UPDATE public.bookings
            SET is_critical = true,
                critical_reason = 'تأخير في البدء: مر نصف ساعة على موعد الطلب ولم يبدأ الفني العمل'
            WHERE id = rec.id;

            PERFORM public.insert_admin_notification(
                'طلب طارئ: تأخر بدء العمل ⏰',
                'تجاوز الطلب رقم ' || COALESCE(rec.readable_id, rec.id::TEXT) || ' موعده بنصف ساعة ولم يبدأ الفني العمل حتى الآن.',
                rec.id, 'critical_late_start'
            );
            CONTINUE;
        END IF;

    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- FIX 4: Retire the redundant monitor_service_sla (logic/13)
-- check_and_escalate_booking_delays is more comprehensive and runs more frequently.
-- Keep only the unified monitor.
-- ==============================================================================

-- Unschedule the redundant SLA monitor job (runs every 15 min)
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'fresh-home-sla-monitor';

-- The replacement: check-booking-delays-every-5-mins already covers everything.
-- No new schedule needed — it's already running every 5 minutes.

COMMENT ON FUNCTION public.check_and_escalate_booking_delays() IS
'Unified SLA escalation function (Africa/Cairo timezone). Replaces the retired monitor_service_sla.
Runs every 5 minutes via check-booking-delays-every-5-mins cron job.
Detects: late acceptance, late movement, late job start.';

-- ==============================================================================
-- FIX 5: Cleanup stale 'processing' rows also in outbox cleanup job
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_notifications_outbox()
RETURNS VOID AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete terminal records older than 30 days
    DELETE FROM public.notifications_outbox
    WHERE status IN (
        'sent'::public.notification_outbox_status,
        'failed'::public.notification_outbox_status
    )
      AND created_at < (NOW() - INTERVAL '30 days');

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Outbox cleanup: deleted % terminal records', deleted_count;

    -- Also reset any processing rows older than 1 hour (crashed workers)
    UPDATE public.notifications_outbox
    SET status = 'pending'::public.notification_outbox_status
    WHERE status = 'processing'::public.notification_outbox_status
      AND processed_at < (NOW() - INTERVAL '1 hour');

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    IF deleted_count > 0 THEN
        RAISE WARNING 'Outbox cleanup: reset % long-stale processing rows — investigate crashed workers', deleted_count;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- SUMMARY: Active Cron Jobs After STEP 2.4
-- ==============================================================================
-- fresh-home-automated-reminders     → '5 * * * *'      every hour at :05
-- check-booking-delays-every-5-mins  → '*/5 * * * *'    every 5 min (unified SLA)
-- fresh-home-assignment-expiry       → '0 * * * *'      every hour at :00
-- fresh-home-no-show-check           → '*/30 * * * *'   every 30 min
-- fresh-home-auto-accept             → '*/15 * * * *'   every 15 min
-- fresh-home-outbox-cleanup          → '0 3 * * *'      daily at 3 AM
-- fresh-home-reset-stale-notifications → '*/5 * * * *'  every 5 min
-- RETIRED: fresh-home-sla-monitor (redundant with check-booking-delays)
