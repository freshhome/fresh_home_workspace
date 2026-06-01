-- ==============================================================================
-- Fresh Home: SLA & Delay Monitoring (Emergency/Critical Tracking)
-- Description: Automatically checks for delayed bookings and escalates them to 
--              the Admin's Emergency/Critical list.
-- ==============================================================================

-- 1. Helper Function: Send Notification to All Admins
CREATE OR REPLACE FUNCTION public.insert_admin_notification(
    p_title TEXT,
    p_body TEXT,
    p_booking_id UUID,
    p_status TEXT
)
RETURNS VOID AS $$
DECLARE
    admin_rec RECORD;
BEGIN
    -- Find all admins based on the roles system
    FOR admin_rec IN 
        SELECT ur.user_id 
        FROM public.user_roles ur 
        JOIN public.roles r ON ur.role_id = r.id 
        WHERE r.name = 'admin'
    LOOP
        -- Re-use the existing idempotent notification sender
        PERFORM public.insert_notification_if_new(
            admin_rec.user_id,
            p_title,
            p_body,
            p_booking_id,
            p_status,
            'emergency_alert'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Core Evaluation Function (Runs periodically)
CREATE OR REPLACE FUNCTION public.check_and_escalate_booking_delays()
RETURNS VOID AS $$
DECLARE
    rec RECORD;
    v_start_timestamp TIMESTAMPTZ;
BEGIN
    -- Loop over all active bookings that are NOT YET marked as critical
    FOR rec IN 
        SELECT * FROM public.bookings
        WHERE status NOT IN ('completed', 'cancelled', 'failed_no_show', 'expired')
          AND is_critical = false
    LOOP
        -- Calculate the exact timestamp of the appointment
        -- We apply 'Asia/Riyadh' (Saudi time) so that the calculation exactly matches the booking time.
        v_start_timestamp := (rec.scheduled_day + rec.start_time_slot) AT TIME ZONE 'Asia/Riyadh';

        -- ----------------------------------------------------------------------
        -- SCENARIO 3 (Extra Security): Technician hasn't even ACCEPTED the order
        -- Rule: 2 hours before the order, if it's still just "assigned", flag it.
        -- ----------------------------------------------------------------------
        IF rec.status = 'assigned' AND NOW() >= (v_start_timestamp - INTERVAL '2 hours') THEN
            UPDATE public.bookings
            SET is_critical = true,
                critical_reason = 'لم يتم القبول: الفني لم يقبل الطلب وتبقى أقل من ساعتين'
            WHERE id = rec.id;
            
            PERFORM public.insert_admin_notification(
                'طلب طارئ: لم يتم القبول ⚠️',
                'الطلب رقم ' || COALESCE(rec.readable_id, rec.id::TEXT) || ' لم يقبله الفني وتبقى أقل من ساعتين على الموعد.',
                rec.id, 'critical_not_accepted'
            );
            
            CONTINUE; -- Skip to next record
        END IF;

        -- ----------------------------------------------------------------------
        -- SCENARIO 1: Technician is LATE to move (Not on the way)
        -- Rule: 30 mins before the order, technician hasn't moved to "on_the_way" or "arrived"
        -- ----------------------------------------------------------------------
        IF rec.status IN ('assigned', 'accepted') AND NOW() >= (v_start_timestamp - INTERVAL '30 minutes') THEN
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

        -- ----------------------------------------------------------------------
        -- SCENARIO 2: Technician is LATE to start the job
        -- Rule: 30 mins AFTER the order time, technician hasn't started (not in_progress)
        -- ----------------------------------------------------------------------
        IF rec.status IN ('assigned', 'accepted', 'on_the_way', 'arrived') AND NOW() >= (v_start_timestamp + INTERVAL '30 minutes') THEN
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
-- 3. CRON JOB SCHEDULING
-- Instructions: Supabase supports pg_cron. We schedule this to run every 5 mins.
-- ==============================================================================

-- Enable the pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Unschedule any previous versions to avoid duplicates
-- SELECT cron.unschedule('check-booking-delays-every-5-mins');

-- Schedule the job to run every 5 minutes
SELECT cron.schedule(
    'check-booking-delays-every-5-mins', -- Job Name
    '*/5 * * * *',                       -- Cron expression (Every 5 minutes)
    $$ SELECT public.check_and_escalate_booking_delays(); $$
);
