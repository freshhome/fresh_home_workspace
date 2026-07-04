-- ==============================================================================
-- Fresh Home: Production Monitoring & Observability Layer (v1.0)
-- File: 20_monitoring_observability.sql
--
-- STEP 4 — Monitoring & Observability
-- Creates comprehensive visibility into all system components:
--   1. Notification delivery health
--   2. Booking lifecycle anomalies
--   3. Cron job execution tracking
--   4. SLA compliance metrics
--   5. Admin operational dashboard queries
--   6. Diagnostic helper functions
-- ==============================================================================

-- ==============================================================================
-- SECTION 1 — NOTIFICATION OBSERVABILITY
-- ==============================================================================

-- View: Real-time notification queue health
CREATE OR REPLACE VIEW public.v_notification_health AS
SELECT
    status,
    COUNT(*)                                          AS count,
    AVG(retry_count)::NUMERIC(4,2)                    AS avg_retries,
    MAX(retry_count)                                  AS max_retries,
    MIN(created_at)                                   AS oldest_record,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '10 minutes') AS stale_count
FROM public.notifications_outbox
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status
ORDER BY status;

COMMENT ON VIEW public.v_notification_health IS
'Real-time snapshot of notification queue. Check stale_count for stuck workers.';

-- View: Notification delivery rate (last 24h, 7d, 30d)
CREATE OR REPLACE VIEW public.v_notification_delivery_rate AS
WITH windows AS (
    SELECT
        COUNT(*) FILTER (WHERE status = 'sent'   AND created_at > NOW() - INTERVAL '24 hours')  AS sent_24h,
        COUNT(*) FILTER (WHERE status = 'failed' AND created_at > NOW() - INTERVAL '24 hours')  AS failed_24h,
        COUNT(*) FILTER (WHERE                       created_at > NOW() - INTERVAL '24 hours')  AS total_24h,
        COUNT(*) FILTER (WHERE status = 'sent'   AND created_at > NOW() - INTERVAL '7 days')    AS sent_7d,
        COUNT(*) FILTER (WHERE status = 'failed' AND created_at > NOW() - INTERVAL '7 days')    AS failed_7d,
        COUNT(*) FILTER (WHERE                       created_at > NOW() - INTERVAL '7 days')    AS total_7d,
        COUNT(*) FILTER (WHERE status = 'pending')                                              AS pending_now,
        COUNT(*) FILTER (WHERE status = 'processing')                                           AS processing_now
    FROM public.notifications_outbox
)
SELECT
    sent_24h,
    failed_24h,
    total_24h,
    CASE WHEN total_24h > 0 THEN ROUND((sent_24h::NUMERIC / total_24h) * 100, 2) ELSE 100 END AS delivery_rate_24h_pct,
    sent_7d,
    failed_7d,
    total_7d,
    CASE WHEN total_7d > 0 THEN ROUND((sent_7d::NUMERIC / total_7d) * 100, 2) ELSE 100 END AS delivery_rate_7d_pct,
    pending_now,
    processing_now
FROM windows;

COMMENT ON VIEW public.v_notification_delivery_rate IS
'Notification delivery success rate for 24h and 7d windows. Alert if delivery_rate_24h_pct < 90.';

-- View: Stuck notifications that need immediate attention
CREATE OR REPLACE VIEW public.v_stuck_notifications AS
SELECT
    n.id              AS outbox_id,
    n.recipient_id,
    n.recipient_type,
    n.event_type,
    n.title,
    n.status,
    n.retry_count,
    n.error_message,
    n.created_at,
    n.processed_at,
    NOW() - n.created_at  AS age,
    t.platform
FROM public.notifications_outbox n
LEFT JOIN public.user_fcm_tokens t ON n.recipient_id = t.user_id
WHERE
    -- Stuck in processing > 5 minutes (crashed worker)
    (n.status = 'processing' AND n.processed_at < NOW() - INTERVAL '5 minutes')
    OR
    -- Old pending with no token (will never be delivered)
    (n.status = 'pending' AND n.created_at < NOW() - INTERVAL '30 minutes'
        AND NOT EXISTS (SELECT 1 FROM public.user_fcm_tokens WHERE user_id = n.recipient_id))
    OR
    -- Max retries reached (permanently failed)
    (n.status = 'failed' AND n.created_at > NOW() - INTERVAL '24 hours')
ORDER BY n.created_at ASC;

COMMENT ON VIEW public.v_stuck_notifications IS
'Notifications requiring manual intervention: crashed workers, missing tokens, permanent failures.';

-- ==============================================================================
-- SECTION 2 — BOOKING LIFECYCLE MONITORING
-- ==============================================================================

-- View: Bookings stuck in non-terminal states too long
CREATE OR REPLACE VIEW public.v_stuck_bookings AS
SELECT
    b.id,
    b.readable_id,
    b.status,
    b.is_critical,
    b.assigned_at,
    b.accepted_at,
    b.scheduled_day,
    b.start_time_slot,
    NOW() - b.updated_at  AS time_in_current_status,
    p_user.first_name || ' ' || p_user.last_name  AS customer_name,
    p_tech.first_name || ' ' || p_tech.last_name  AS technician_name
FROM public.bookings b
LEFT JOIN public.profiles p_user ON p_user.id = b.user_id
LEFT JOIN public.profiles p_tech ON p_tech.id = b.technician_id
WHERE b.status NOT IN (
    'completed', 'cancelled', 'expired', 'failed_no_show'
)
AND (
    -- Assigned > 4 hours without acceptance
    (b.status = 'assigned'    AND b.updated_at < NOW() - INTERVAL '4 hours')
    OR
    -- Accepted > 2 hours past scheduled time without movement
    (b.status = 'accepted'    AND (b.scheduled_day + b.start_time_slot)::TIMESTAMPTZ < NOW() - INTERVAL '2 hours')
    OR
    -- On the way for > 2 hours (unrealistic travel time)
    (b.status = 'on_the_way'  AND b.updated_at < NOW() - INTERVAL '2 hours')
    OR
    -- Arrived but not started for > 1 hour
    (b.status = 'arrived'     AND b.updated_at < NOW() - INTERVAL '1 hour')
    OR
    -- In progress for > 6 hours (abnormally long service)
    (b.status = 'in_progress' AND b.updated_at < NOW() - INTERVAL '6 hours')
)
ORDER BY b.updated_at ASC;

COMMENT ON VIEW public.v_stuck_bookings IS
'Bookings that have been in the same non-terminal state for an abnormally long time.';

-- View: Bookings missing audit trail (integrity check)
CREATE OR REPLACE VIEW public.v_bookings_missing_audit AS
SELECT
    b.id,
    b.readable_id,
    b.status,
    b.created_at,
    b.updated_at
FROM public.bookings b
WHERE NOT EXISTS (
    SELECT 1 FROM public.booking_events be WHERE be.booking_id = b.id
)
  AND b.created_at > NOW() - INTERVAL '7 days';

COMMENT ON VIEW public.v_bookings_missing_audit IS
'Recent bookings with no booking_events records — indicates State Machine bypass.';

-- View: SLA compliance summary
CREATE OR REPLACE VIEW public.v_sla_compliance AS
WITH booking_stats AS (
    SELECT
        COUNT(*) FILTER (WHERE scheduled_day >= CURRENT_DATE - 7)                                   AS bookings_last_7d,
        COUNT(*) FILTER (WHERE status = 'completed' AND scheduled_day >= CURRENT_DATE - 7)          AS completed_last_7d,
        COUNT(*) FILTER (WHERE status = 'cancelled'
                              AND scheduled_day >= CURRENT_DATE - 7)                                AS cancelled_last_7d,
        COUNT(*) FILTER (WHERE status = 'failed_no_show' AND scheduled_day >= CURRENT_DATE - 7)     AS no_show_last_7d,
        COUNT(*) FILTER (WHERE is_critical = TRUE AND scheduled_day >= CURRENT_DATE - 7)            AS critical_last_7d,
        AVG(EXTRACT(EPOCH FROM (accepted_at - assigned_at)) / 60)
            FILTER (WHERE accepted_at IS NOT NULL AND scheduled_day >= CURRENT_DATE - 7)            AS avg_accept_time_minutes
    FROM public.bookings
)
SELECT
    bookings_last_7d,
    completed_last_7d,
    cancelled_last_7d,
    no_show_last_7d,
    critical_last_7d,
    ROUND(avg_accept_time_minutes::NUMERIC, 1)          AS avg_accept_time_minutes,
    CASE WHEN bookings_last_7d > 0
        THEN ROUND((completed_last_7d::NUMERIC / bookings_last_7d) * 100, 2)
        ELSE 0 END                                      AS completion_rate_pct,
    CASE WHEN bookings_last_7d > 0
        THEN ROUND((cancelled_last_7d::NUMERIC / bookings_last_7d) * 100, 2)
        ELSE 0 END                                      AS cancellation_rate_pct,
    CASE WHEN bookings_last_7d > 0
        THEN ROUND(((bookings_last_7d - critical_last_7d)::NUMERIC / bookings_last_7d) * 100, 2)
        ELSE 100 END                                    AS sla_compliance_pct
FROM booking_stats;

COMMENT ON VIEW public.v_sla_compliance IS
'Weekly SLA compliance metrics. Target: completion_rate > 85%, sla_compliance > 90%.';

-- ==============================================================================
-- SECTION 3 — CRON JOB MONITORING
-- ==============================================================================

-- View: Cron job execution health (requires pg_cron)
CREATE OR REPLACE VIEW public.v_cron_health AS
SELECT
    j.jobname,
    j.schedule,
    j.active,
    r.start_time                                         AS last_run_start,
    r.end_time                                           AS last_run_end,
    EXTRACT(EPOCH FROM (r.end_time - r.start_time))      AS last_duration_seconds,
    r.status                                             AS last_status,
    r.return_message                                     AS last_error,
    CASE
        WHEN r.status = 'succeeded' THEN '✅ healthy'
        WHEN r.status = 'failed'    THEN '❌ failed'
        WHEN r.start_time < NOW() - INTERVAL '2 hours' THEN '⚠️ stale'
        ELSE '🔄 running'
    END                                                  AS health_indicator
FROM cron.job j
LEFT JOIN LATERAL (
    SELECT *
    FROM cron.job_run_details d
    WHERE d.jobid = j.jobid
    ORDER BY d.start_time DESC
    LIMIT 1
) r ON TRUE
ORDER BY j.jobname;

COMMENT ON VIEW public.v_cron_health IS
'Real-time cron job health. Check for failed or stale entries.';

-- View: Failed cron runs in last 24 hours
CREATE OR REPLACE VIEW public.v_cron_failures AS
SELECT
    j.jobname,
    r.start_time,
    r.end_time,
    r.status,
    r.return_message   AS error_message,
    EXTRACT(EPOCH FROM (r.end_time - r.start_time)) AS duration_seconds
FROM cron.job_run_details r
JOIN cron.job j ON j.jobid = r.jobid
WHERE r.status = 'failed'
  AND r.start_time > NOW() - INTERVAL '24 hours'
ORDER BY r.start_time DESC;

COMMENT ON VIEW public.v_cron_failures IS
'Failed cron executions in the last 24 hours. Alert if any rows appear here.';

-- ==============================================================================
-- SECTION 4 — TECHNICIAN PERFORMANCE MONITORING
-- ==============================================================================

-- View: Technician response and delivery performance
CREATE OR REPLACE VIEW public.v_technician_performance AS
SELECT
    p.first_name || ' ' || p.last_name                                   AS technician_name,
    tp.user_id                                                            AS technician_id,
    COUNT(b.id) FILTER (WHERE b.scheduled_day >= CURRENT_DATE - 30)      AS bookings_last_30d,
    COUNT(b.id) FILTER (WHERE b.status = 'completed'
                             AND b.scheduled_day >= CURRENT_DATE - 30)   AS completed_last_30d,
    COUNT(b.id) FILTER (WHERE b.status = 'failed_no_show'
                             AND b.scheduled_day >= CURRENT_DATE - 30)   AS no_shows_last_30d,
    ROUND(AVG(EXTRACT(EPOCH FROM (b.accepted_at - b.assigned_at)) / 60)
        FILTER (WHERE b.accepted_at IS NOT NULL
                    AND b.scheduled_day >= CURRENT_DATE - 30)::NUMERIC, 1)
                                                                          AS avg_accept_min,
    tp.rating,
    tp.is_available
FROM public.technician_profiles tp
JOIN public.profiles p ON p.id = tp.user_id
LEFT JOIN public.bookings b ON b.technician_id = tp.user_id
GROUP BY tp.user_id, p.first_name, p.last_name, tp.rating, tp.is_available
ORDER BY completed_last_30d DESC;

COMMENT ON VIEW public.v_technician_performance IS
'30-day technician performance report. Check no_shows_last_30d for reliability issues.';

-- ==============================================================================
-- SECTION 5 — DIAGNOSTIC HELPER FUNCTIONS
-- ==============================================================================

-- Function: Full diagnostic dump for a specific booking
CREATE OR REPLACE FUNCTION public.diagnose_booking(p_booking_id UUID)
RETURNS TABLE (
    section     TEXT,
    key         TEXT,
    value       TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Booking core info
    RETURN QUERY
    SELECT 'BOOKING'::TEXT, 'status',        b.status::TEXT FROM public.bookings b WHERE b.id = p_booking_id;
    RETURN QUERY
    SELECT 'BOOKING'::TEXT, 'is_critical',   b.is_critical::TEXT FROM public.bookings b WHERE b.id = p_booking_id;
    RETURN QUERY
    SELECT 'BOOKING'::TEXT, 'scheduled_day', b.scheduled_day::TEXT FROM public.bookings b WHERE b.id = p_booking_id;
    RETURN QUERY
    SELECT 'BOOKING'::TEXT, 'time_in_status', (NOW() - b.updated_at)::TEXT FROM public.bookings b WHERE b.id = p_booking_id;

    -- Audit trail
    RETURN QUERY
    SELECT 'AUDIT'::TEXT, 'total_events',
           COUNT(*)::TEXT
    FROM public.booking_events be WHERE be.booking_id = p_booking_id;

    RETURN QUERY
    SELECT 'AUDIT'::TEXT, 'last_event',
           be.event_type || ' by ' || COALESCE(be.actor_role, 'system') || ' at ' || be.created_at::TEXT
    FROM public.booking_events be
    WHERE be.booking_id = p_booking_id
    ORDER BY be.created_at DESC LIMIT 1;

    -- Notification history
    RETURN QUERY
    SELECT 'NOTIFICATIONS'::TEXT, 'outbox_count',
           COUNT(*)::TEXT
    FROM public.notifications_outbox n
    WHERE (n.data->>'booking_id')::UUID = p_booking_id;

    RETURN QUERY
    SELECT 'NOTIFICATIONS'::TEXT, 'sent_count',
           COUNT(*)::TEXT
    FROM public.notifications_outbox n
    WHERE (n.data->>'booking_id')::UUID = p_booking_id
      AND n.status = 'sent';

    RETURN QUERY
    SELECT 'NOTIFICATIONS'::TEXT, 'failed_count',
           COUNT(*)::TEXT
    FROM public.notifications_outbox n
    WHERE (n.data->>'booking_id')::UUID = p_booking_id
      AND n.status = 'failed';

    -- FCM token check
    RETURN QUERY
    SELECT 'FCM'::TEXT, 'customer_has_token',
           EXISTS(SELECT 1 FROM public.user_fcm_tokens t
                  JOIN public.bookings b2 ON b2.user_id = t.user_id
                  WHERE b2.id = p_booking_id)::TEXT;

    RETURN QUERY
    SELECT 'FCM'::TEXT, 'technician_has_token',
           EXISTS(SELECT 1 FROM public.user_fcm_tokens t
                  JOIN public.bookings b2 ON b2.technician_id = t.user_id
                  WHERE b2.id = p_booking_id)::TEXT;
END;
$$;

COMMENT ON FUNCTION public.diagnose_booking(UUID) IS
'Full diagnostic dump for a booking. Shows status, audit trail, notification history, FCM token presence.
Usage: SELECT * FROM public.diagnose_booking(''booking-uuid-here'');';

-- Function: System-wide health check (run to get instant overview)
DROP FUNCTION IF EXISTS public.system_health_check();
CREATE OR REPLACE FUNCTION public.system_health_check()
RETURNS TABLE (
    component   TEXT,
    health      TEXT,   -- renamed from 'status' to avoid ambiguity with table columns
    detail      TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pending         INTEGER;
    v_processing      INTEGER;
    v_stuck           INTEGER;
    v_failed_24h      INTEGER;
    v_delivery_rate   NUMERIC;
    v_stuck_bookings  INTEGER;
    v_missing_audit   INTEGER;
    v_cron_failures   INTEGER;
BEGIN
    -- ── Notification queue metrics ────────────────────────────────────────────
    -- Using table alias 'n' to avoid conflict with output column 'health'
    SELECT COUNT(*) INTO v_pending    FROM public.notifications_outbox n WHERE n.status = 'pending';
    SELECT COUNT(*) INTO v_processing FROM public.notifications_outbox n WHERE n.status = 'processing';
    SELECT COUNT(*) INTO v_stuck      FROM public.notifications_outbox n
        WHERE n.status = 'processing' AND n.processed_at < NOW() - INTERVAL '5 minutes';
    SELECT COUNT(*) INTO v_failed_24h FROM public.notifications_outbox n
        WHERE n.status = 'failed' AND n.created_at > NOW() - INTERVAL '24 hours';
    SELECT CASE WHEN s.total > 0 THEN ROUND((s.sent::NUMERIC / s.total) * 100, 1) ELSE 100 END
    INTO v_delivery_rate
    FROM (
        SELECT COUNT(*) FILTER (WHERE n2.status = 'sent') AS sent, COUNT(*) AS total
        FROM public.notifications_outbox n2 WHERE n2.created_at > NOW() - INTERVAL '24 hours'
    ) s;

    component := 'NOTIFICATIONS';
    health    := CASE WHEN v_pending > 100 THEN '⚠️ HIGH QUEUE' ELSE '✅ OK' END;
    detail    := 'Pending: ' || v_pending || ', Processing: ' || v_processing;
    RETURN NEXT;

    component := 'NOTIFICATIONS';
    health    := CASE WHEN v_stuck > 0 THEN '❌ STUCK WORKERS' ELSE '✅ OK' END;
    detail    := 'Stuck in processing > 5 min: ' || v_stuck;
    RETURN NEXT;

    component := 'NOTIFICATIONS';
    health    := CASE WHEN v_delivery_rate < 90 THEN '⚠️ LOW DELIVERY RATE' ELSE '✅ OK' END;
    detail    := 'Delivery rate (24h): ' || v_delivery_rate || '%';
    RETURN NEXT;

    component := 'NOTIFICATIONS';
    health    := CASE WHEN v_failed_24h > 0 THEN '⚠️ PERMANENT FAILURES' ELSE '✅ OK' END;
    detail    := 'Permanent failures (24h): ' || v_failed_24h;
    RETURN NEXT;

    -- ── Booking lifecycle ─────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_stuck_bookings FROM public.v_stuck_bookings;
    SELECT COUNT(*) INTO v_missing_audit  FROM public.v_bookings_missing_audit;

    component := 'BOOKINGS';
    health    := CASE WHEN v_stuck_bookings > 0 THEN '⚠️ STUCK BOOKINGS' ELSE '✅ OK' END;
    detail    := 'Bookings stuck in same state too long: ' || v_stuck_bookings;
    RETURN NEXT;

    component := 'BOOKINGS';
    health    := CASE WHEN v_missing_audit > 0 THEN '❌ AUDIT GAPS DETECTED' ELSE '✅ OK' END;
    detail    := 'Recent bookings with no audit trail: ' || v_missing_audit;
    RETURN NEXT;

    -- ── Cron jobs ─────────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_cron_failures
    FROM cron.job_run_details r
    WHERE r.status = 'failed' AND r.start_time > NOW() - INTERVAL '1 hour';

    component := 'CRON';
    health    := CASE WHEN v_cron_failures > 0 THEN '❌ CRON FAILURES' ELSE '✅ OK' END;
    detail    := 'Failed cron runs (last hour): ' || v_cron_failures;
    RETURN NEXT;

    RETURN;
END;
$$;

COMMENT ON FUNCTION public.system_health_check() IS
'Instant system-wide health overview. Run this first when investigating any issue.
Usage: SELECT * FROM public.system_health_check();';

-- ==============================================================================
-- SECTION 6 — DAILY METRICS SNAPSHOT (for Admin Dashboard)
-- ==============================================================================

CREATE OR REPLACE VIEW public.v_daily_operations_summary AS
SELECT
    CURRENT_DATE                                                              AS report_date,
    -- Bookings
    COUNT(b.id) FILTER (WHERE b.created_at::DATE = CURRENT_DATE)            AS bookings_created_today,
    COUNT(b.id) FILTER (WHERE b.status = 'completed'::public.order_status_v2
                             AND b.updated_at::DATE = CURRENT_DATE)         AS completions_today,
    COUNT(b.id) FILTER (WHERE b.status::TEXT LIKE '%cancelled%'              -- cast enum→text for pattern match
                             AND b.updated_at::DATE = CURRENT_DATE)         AS cancellations_today,
    COUNT(b.id) FILTER (WHERE b.is_critical = TRUE
                             AND b.updated_at::DATE = CURRENT_DATE)         AS escalations_today,
    COUNT(b.id) FILTER (WHERE b.status NOT IN (
        'completed'::public.order_status_v2,
        'cancelled'::public.order_status_v2,
        'expired'::public.order_status_v2,
        'failed_no_show'::public.order_status_v2
    ))                                                                       AS active_bookings_now,
    -- Notifications
    (SELECT COUNT(*) FROM public.notifications_outbox
     WHERE status = 'sent' AND sent_at::DATE = CURRENT_DATE)                AS notifications_sent_today,
    (SELECT COUNT(*) FROM public.notifications_outbox
     WHERE status = 'failed' AND created_at::DATE = CURRENT_DATE)           AS notifications_failed_today,
    (SELECT COUNT(*) FROM public.notifications_outbox
     WHERE status = 'pending')                                               AS notifications_queued_now
FROM public.bookings b;

COMMENT ON VIEW public.v_daily_operations_summary IS
'Single-row daily operations summary. Refresh every 5 minutes on admin dashboard.';

-- ==============================================================================
-- SECTION 7 — MONITORING CRON JOB
-- Add a daily system health snapshot to cron.job_run_details log
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.run_daily_health_snapshot()
RETURNS VOID AS $$
DECLARE
    v_result RECORD;
    v_issues TEXT[] := '{}';
BEGIN
    FOR v_result IN SELECT * FROM public.system_health_check()
    LOOP
        IF v_result.status NOT LIKE '%✅%' THEN
            v_issues := array_append(v_issues, v_result.component || ': ' || v_result.detail);
        END IF;
    END LOOP;

    IF array_length(v_issues, 1) > 0 THEN
        RAISE WARNING 'SYSTEM HEALTH ISSUES DETECTED: %', array_to_string(v_issues, ' | ');
    ELSE
        RAISE NOTICE 'System health check passed — all components nominal.';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT cron.unschedule(jobid)
FROM cron.job WHERE jobname = 'fresh-home-daily-health-check';

SELECT cron.schedule(
    'fresh-home-daily-health-check',
    '0 6 * * *',  -- Every day at 6 AM Cairo time
    $$ SELECT public.run_daily_health_snapshot(); $$
);

COMMENT ON FUNCTION public.run_daily_health_snapshot() IS
'Daily automated health check. Issues are logged as WARNINGs in pg_cron logs.';
