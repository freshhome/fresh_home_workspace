-- ==============================================================================
-- Fresh Home: Push Notifications Activation (Phase 7)
-- Description: Enables pg_net, activates the push notification trigger, 
--              and links it to the send-push-notification edge function.
-- ==============================================================================

-- 1. تمكين الإضافات اللازمة للاتصال بالإنترنت من داخل قاعدة البيانات
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. تحديث وظيفة إطلاق الإشعار (Trigger Function)
-- تقوم هذه الوظيفة باستدعاء الـ Edge Function عند كل إشعار جديد في الجدول
CREATE OR REPLACE FUNCTION public.trigger_push_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- استدعاء Edge Function: send-push-notification
    -- نقوم بإرسال السجل (record) بالكامل كجسم للطلب (JSON)
    PERFORM net.http_post(
        url := (SELECT value FROM (SELECT COALESCE(
            NULLIF(current_setting('app.settings.project_url', true), ''),
            'https://' || (NULLIF(current_setting('request.headers', true), '')::jsonb->>'host')
        ) as value) s) || '/functions/v1/send-push-notification',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || COALESCE(current_setting('app.settings.service_role_key', true), '')
        ),
        body := jsonb_build_object('record', row_to_json(NEW))
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. تفعيل الـ Trigger على جدول الإشعارات
-- يتم التفعيل بعد كل عملية إدخال (INSERT) ناجحة لإشعار جديد
DROP TRIGGER IF EXISTS tr_push_notification ON public.notifications;
CREATE TRIGGER tr_push_notification
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_push_notification();

-- 4. تعليق توضيحي للإدارة
COMMENT ON FUNCTION public.trigger_push_notification() 
IS 'Dispatches new notifications to the send-push-notification Edge Function via pg_net.';

-- 5. ضمان وجود الصلاحيات لـ pg_net
GRANT USAGE ON SCHEMA net TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA net TO postgres;
