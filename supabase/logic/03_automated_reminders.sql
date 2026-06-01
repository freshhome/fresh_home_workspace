-- ==============================================================================
-- Fresh Home: Automated Reminders Engine (v1.0)
-- Description: Scheduled job logic for Technician (8 AM) and Customer (6 PM) reminders.
-- Timezone: Africa/Cairo (Egypt)
-- ==============================================================================

-- 1. Enable pg_cron if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Stored Procedure for Reminders
CREATE OR REPLACE FUNCTION public.process_automated_reminders()
RETURNS VOID AS $$
DECLARE
    v_now_egypt      TIMESTAMPTZ := NOW() AT TIME ZONE 'Africa/Cairo';
    v_today_egypt    DATE := v_now_egypt::DATE;
    v_hour_egypt     INT := EXTRACT(HOUR FROM v_now_egypt);
    v_booking        RECORD;
BEGIN
    -- ===========================================================
    -- PHASE A: Technician Reminder (8:00 AM Egypt)
    -- Goal: Remind them to confirm their attendance for today.
    -- ===========================================================
    IF v_hour_egypt = 8 THEN
        FOR v_booking IN (
            SELECT b.*, p.first_name, COALESCE(b.readable_id, b.id::TEXT) as display_id
            FROM public.bookings b
            JOIN public.profiles p ON b.technician_id = p.id
            WHERE b.scheduled_day::DATE = v_today_egypt
              AND b.status = 'accepted'
              AND b.is_confirmed_today = FALSE
              AND (b.last_reminder_at IS NULL OR b.last_reminder_at::DATE != v_today_egypt)
        ) LOOP
            -- Enqueue Technician Reminder
            PERFORM public.enqueue_notification(
                'DAILY_CONFIRM_REMINDER',
                'technician',
                v_booking.technician_id,
                'تذكير بموعد اليوم ⚡',
                'صباح الخير ' || v_booking.first_name || '. لديك موعد اليوم (' || v_booking.display_id || '). يرجى تأكيد الحضور الآن لفتح بيانات العميل.',
                jsonb_build_object('booking_id', v_booking.id, 'status', v_booking.status, 'action_type', 'daily_confirm')
            );

            -- Mark as reminded
            UPDATE public.bookings SET last_reminder_at = NOW() WHERE id = v_booking.id;
        END LOOP;
    END IF;

    -- ===========================================================
    -- PHASE B: Customer Reminder (6:00 PM Egypt)
    -- Goal: Remind them of their appointment tomorrow.
    -- ===========================================================
    IF v_hour_egypt = 18 THEN
        FOR v_booking IN (
            SELECT b.*, COALESCE(b.readable_id, b.id::TEXT) as display_id
            FROM public.bookings b
            WHERE b.scheduled_day::DATE = v_today_egypt + 1
              AND b.status IN ('assigned', 'accepted')
              AND b.created_at < (NOW() - INTERVAL '12 hours') -- Only remind if booked before 6:00 AM today
              AND (b.last_reminder_at IS NULL OR b.last_reminder_at::DATE != v_today_egypt)
        ) LOOP
            -- Enqueue Customer Reminder
            PERFORM public.enqueue_notification(
                'APPOINTMENT_REMINDER',
                'customer',
                v_booking.user_id,
                'تذكير بموعد الخدمة غداً 🏠',
                'نود تذكيركم بموعد خدمتكم غداً (' || v_booking.display_id || '). سيتواصل معكم الفني فور جهوزيته. فريق فريش هوم في انتظاركم!',
                jsonb_build_object('booking_id', v_booking.id, 'status', v_booking.status, 'action_type', 'appointment_reminder')
            );

            -- Mark as reminded
            UPDATE public.bookings SET last_reminder_at = NOW() WHERE id = v_booking.id;
        END LOOP;
    END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Schedule the Cron Job (Runs every hour at minute 5)
-- We run every hour and the procedure itself checks if the hour is 8 or 18.
SELECT cron.schedule(
    'fresh-home-automated-reminders',
    '5 * * * *',
    'SELECT public.process_automated_reminders();'
);

COMMENT ON FUNCTION public.process_automated_reminders() 
IS 'Runs every hour via pg_cron to send Technician (8 AM) and Customer (6 PM) reminders for appointments in Egypt Time.';
