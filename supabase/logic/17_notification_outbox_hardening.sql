-- ==============================================================================
-- Fresh Home: Notification Outbox Hardening (v2.0)
-- File: 17_notification_outbox_hardening.sql
--
-- STEP 2.2 — Notification Outbox Hardening
-- Fixes:
--   1. SLA Admin alerts: NULL recipient_id means alerts never reach anyone
--   2. Deduplication: improve guard to handle SLA repeated triggers
--   3. Outbox cleanup: auto-delete sent/failed records older than 30 days
--   4. insert_notification_if_new: fix recipient_type always being 'customer'
-- ==============================================================================

-- ==============================================================================
-- FIX 1: Replace monitor_service_sla to use proper Admin fanout
-- (was sending to NULL recipient_id — alerts never appeared in v_pending_notifications)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.monitor_service_sla()
RETURNS VOID AS $$
DECLARE
    v_rec       RECORD;
    v_admin_rec RECORD;
BEGIN
    -- PHASE 1: Late Confirmation (assigned > 2 hours without acceptance)
    FOR v_rec IN
        SELECT b.id, b.readable_id, b.assigned_at
        FROM public.bookings b
        WHERE b.status = 'assigned'::public.order_status_v2
          AND b.assigned_at < (NOW() - INTERVAL '2 hours')
          AND b.is_critical = FALSE
    LOOP
        UPDATE public.bookings
        SET is_critical = TRUE,
            critical_reason = 'تأخر الفني في قبول الطلب (أكثر من ساعتين)'
        WHERE id = v_rec.id;

        -- Fan out to ALL admins (not NULL recipient)
        FOR v_admin_rec IN
            SELECT ur.user_id
            FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE r.name = 'admin'
        LOOP
            PERFORM public.enqueue_notification(
                'SLA_ALERT_LATE_CONFIRMATION',
                'admin'::public.notification_recipient_type,
                v_admin_rec.user_id,  -- ← FIXED: real UUID, not NULL
                '⚠️ تنبيه: تأخر في قبول طلب',
                'الطلب رقم (' || COALESCE(v_rec.readable_id, v_rec.id::TEXT) || ') لم يتم قبوله من قِبل الفني منذ ساعتين.',
                jsonb_build_object('booking_id', v_rec.id, 'severity', 'high', 'action_type', 'sla_alert')
            );
        END LOOP;
    END LOOP;

    -- PHASE 2: Late Movement (scheduled time passed, still accepted/ready)
    FOR v_rec IN
        SELECT b.id, b.readable_id, b.scheduled_day, b.start_time_slot
        FROM public.bookings b
        WHERE b.status IN ('accepted'::public.order_status_v2, 'ready'::public.order_status_v2)
          AND (b.scheduled_day + b.start_time_slot) < NOW()
          AND b.is_critical = FALSE
    LOOP
        UPDATE public.bookings
        SET is_critical = TRUE,
            critical_reason = 'موعد الخدمة بدأ والفني لم يتحرك بعد'
        WHERE id = v_rec.id;

        -- Fan out to ALL admins
        FOR v_admin_rec IN
            SELECT ur.user_id
            FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE r.name = 'admin'
        LOOP
            PERFORM public.enqueue_notification(
                'SLA_ALERT_LATE_MOVEMENT',
                'admin'::public.notification_recipient_type,
                v_admin_rec.user_id,  -- ← FIXED: real UUID, not NULL
                '🚨 حالة طارئة: تأخر في البدء',
                'موعد الطلب رقم (' || COALESCE(v_rec.readable_id, v_rec.id::TEXT) || ') بدأ بالفعل والفني لم يغير حالته إلى "في الطريق".',
                jsonb_build_object('booking_id', v_rec.id, 'severity', 'critical', 'action_type', 'sla_alert')
            );
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- FIX 2: Fix insert_notification_if_new recipient_type
-- (was always hardcoded to 'customer' even for technician/admin recipients)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.insert_notification_if_new(
    p_user_id       UUID,
    p_title         TEXT,
    p_body          TEXT,
    p_booking_id    UUID,
    p_status        TEXT,
    p_action_type   TEXT DEFAULT 'status_change'
)
RETURNS VOID AS $$
DECLARE
    v_recipient_type public.notification_recipient_type;
BEGIN
    -- Resolve recipient type by checking their actual role
    -- Defaults to 'customer' if no special role found
    IF EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_user_id AND r.name = 'admin'
    ) THEN
        v_recipient_type := 'admin';
    ELSIF EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_user_id AND r.name = 'technician'
    ) THEN
        v_recipient_type := 'technician';
    ELSE
        v_recipient_type := 'customer';
    END IF;

    -- DEDUPLICATION GUARD: Prevent same (user, booking, status) combination
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications_outbox
        WHERE recipient_id = p_user_id
          AND (data->>'booking_id')::UUID = p_booking_id
          AND data->>'status' = p_status
          AND status != 'failed'::public.notification_outbox_status
          AND created_at > (NOW() - INTERVAL '1 hour') -- Only deduplicate within last hour
    ) THEN
        PERFORM public.enqueue_notification(
            'ORDER_STATUS_CHANGE',
            v_recipient_type,
            p_user_id,
            p_title,
            p_body,
            jsonb_build_object(
                'booking_id',  p_booking_id,
                'status',      p_status,
                'action_type', p_action_type
            )
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- FIX 3: Outbox Cleanup Job (prevent table bloat)
-- Auto-delete records older than 30 days that are in terminal states
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_notifications_outbox()
RETURNS VOID AS $$
BEGIN
    DELETE FROM public.notifications_outbox
    WHERE status IN ('sent'::public.notification_outbox_status, 'failed'::public.notification_outbox_status)
      AND created_at < (NOW() - INTERVAL '30 days');

    RAISE NOTICE 'Notifications outbox cleanup completed.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule cleanup to run daily at 3 AM
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'fresh-home-outbox-cleanup';

SELECT cron.schedule(
    'fresh-home-outbox-cleanup',
    '0 3 * * *',
    $$ SELECT public.cleanup_notifications_outbox(); $$
);

-- ==============================================================================
-- FIX 4: Rebuild outbox relay trigger
-- Simple and reliable — no Authorization header needed because Edge Function
-- is deployed with --no-verify-jwt flag.
-- EXCEPTION block ensures notification failures NEVER block booking transactions.
-- ==============================================================================

DROP TRIGGER IF EXISTS tr_notify_outbox_inserted ON public.notifications_outbox;
DROP TRIGGER IF EXISTS tr_notify_outbox_updated ON public.notifications_outbox;
DROP FUNCTION IF EXISTS public.invoke_notification_relay();

CREATE OR REPLACE FUNCTION public.invoke_notification_relay()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM net.http_post(
        url     := 'https://dsddwqdixsdhaspfafuy.supabase.co/functions/v1/notify-outbox-relay',
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body    := '{}'
    );
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- CRITICAL: Never block the booking transaction due to a notification error
    RAISE WARNING 'invoke_notification_relay trigger failed: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: fire on every new notification inserted in the outbox
CREATE TRIGGER tr_notify_outbox_inserted
AFTER INSERT ON public.notifications_outbox
FOR EACH ROW
EXECUTE FUNCTION public.invoke_notification_relay();

COMMENT ON FUNCTION public.invoke_notification_relay() IS
'Calls notify-outbox-relay Edge Function (deployed with --no-verify-jwt) on every outbox INSERT.
EXCEPTION block guarantees transaction safety — notification failures are logged as warnings only.';
