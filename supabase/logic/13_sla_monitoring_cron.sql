-- ==============================================================================
-- Fresh Home: SLA Monitoring & Auto-Escalation (v1.0)
-- Description: Automated detection of late technician responses and movements.
-- ==============================================================================

-- 1. SLA Monitoring Function
CREATE OR REPLACE FUNCTION public.monitor_service_sla()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    -- ===========================================================
    -- PHASE 1: Late Confirmation Detection (Step 4.1)
    -- If assigned for > 2 hours without acceptance
    -- ===========================================================
    FOR v_rec IN 
        SELECT b.id, b.readable_id, b.assigned_at
        FROM public.bookings b
        WHERE b.status = 'assigned'
          AND b.assigned_at < (NOW() - INTERVAL '2 hours')
          AND b.is_critical = FALSE
    LOOP
        -- Mark as Critical
        UPDATE public.bookings 
        SET is_critical = TRUE, 
            critical_reason = 'تأخر الفني في قبول الطلب (أكثر من ساعتين)'
        WHERE id = v_rec.id;

        -- Enqueue Alert for Admin
        PERFORM public.enqueue_notification(
            'SLA_ALERT_LATE_CONFIRMATION',
            'admin',
            NULL, -- System-wide admin alert
            '⚠️ تنبيه: تأخر في قبول طلب',
            'الطلب رقم (' || COALESCE(v_rec.readable_id, v_rec.id::TEXT) || ') لم يتم قبوله من قِبل الفني منذ ساعتين.',
            jsonb_build_object('booking_id', v_rec.id, 'severity', 'high')
        );
    END LOOP;

    -- ===========================================================
    -- PHASE 2: Late Movement Detection (Step 4.2)
    -- If scheduled time passed and tech is not "On The Way"
    -- ===========================================================
    FOR v_rec IN 
        SELECT b.id, b.readable_id, b.scheduled_day, b.start_time_slot
        FROM public.bookings b
        WHERE b.status IN ('accepted', 'ready')
          AND (b.scheduled_day + b.start_time_slot) < NOW()
          AND b.is_critical = FALSE
    LOOP
        -- Mark as Critical
        UPDATE public.bookings 
        SET is_critical = TRUE, 
            critical_reason = 'موعد الخدمة بدأ والفني لم يتحرك بعد'
        WHERE id = v_rec.id;

        -- Enqueue Alert for Admin
        PERFORM public.enqueue_notification(
            'SLA_ALERT_LATE_MOVEMENT',
            'admin',
            NULL,
            '🚨 حالة طارئة: تأخر في البدء',
            'موعد الطلب رقم (' || COALESCE(v_rec.readable_id, v_rec.id::TEXT) || ') بدأ بالفعل والفني لم يغير حالته إلى "في الطريق".',
            jsonb_build_object('booking_id', v_rec.id, 'severity', 'critical')
        );
    END LOOP;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Schedule SLA Monitoring (Runs every 15 minutes)
SELECT cron.schedule(
    'fresh-home-sla-monitor',
    '*/15 * * * *',
    'SELECT public.monitor_service_sla();'
);

COMMENT ON FUNCTION public.monitor_service_sla() IS 'Monitors bookings for SLA breaches and escalates to Admin Outbox automatically.';
