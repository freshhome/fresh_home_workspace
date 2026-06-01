-- [ignoring loop detection]
-- ==============================================================================
-- Fresh Home: Master Notifications Reset & Optimization
-- Description: Deletes all old/duplicate notifications and cleanly installs
--              the ONLY correct notification system to prevent any duplicates.
-- ==============================================================================

-- 1. مسح جميع الإشعارات القديمة والمتكررة (تصفير الجدول)
TRUNCATE TABLE public.notifications CASCADE;

-- 2. إزالة أي مشغلات (Triggers) قديمة لمنع التداخل
DROP TRIGGER IF EXISTS tr_on_booking_status_change_notify ON public.bookings;
DROP TRIGGER IF EXISTS tr_booking_status_notify ON public.bookings;
DROP TRIGGER IF EXISTS tr_push_notification ON public.bookings; -- إذا كان مكرراً أو متعارضاً (اختياري)

-- 3. بناء الدالة الشاملة والنهائية (The Master Function v2.0)
CREATE OR REPLACE FUNCTION public.handle_booking_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_title TEXT;
    v_body  TEXT;
    v_recipient_id UUID;
    v_readable_id TEXT;
    v_user_name TEXT;
    v_tech_name TEXT;
    v_service_name TEXT;
    v_is_new_booking BOOLEAN;
    v_status_changed BOOLEAN;
    v_tech_changed BOOLEAN;
BEGIN
    v_is_new_booking := (TG_OP = 'INSERT');
    v_status_changed := v_is_new_booking OR (NEW.status IS DISTINCT FROM OLD.status);
    v_tech_changed := NOT v_is_new_booking AND (NEW.technician_id IS DISTINCT FROM OLD.technician_id);

    IF NOT v_status_changed AND NOT v_tech_changed THEN
        RETURN NEW;
    END IF;

    v_readable_id := COALESCE(NEW.readable_id, NEW.id::TEXT);
    SELECT title->>'ar' INTO v_service_name FROM public.sub_services WHERE id = NEW.service_id;
    v_service_name := COALESCE(v_service_name, 'الخدمة المطلوبة');

    -- ==========================================
    -- أ. الحجوزات الجديدة كلياً
    -- ==========================================
    IF v_is_new_booking THEN
        INSERT INTO public.notifications (user_id, title, body, metadata)
        VALUES (
            NEW.user_id,
            'تم استلام طلبك بنجاح ✅',
            'تم استلام طلبك لـ(' || v_service_name || ') برقم ' || v_readable_id || ' وجاري تعيين فني له.',
            jsonb_build_object('booking_id', NEW.id, 'status', NEW.status, 'action_type', 'booking_created')
        );
    END IF;

    -- ==========================================
    -- ب. نقل الأوردر من فني لآخر
    -- ==========================================
    IF v_tech_changed THEN
        IF OLD.technician_id IS NOT NULL THEN
            INSERT INTO public.notifications (user_id, title, body, metadata)
            VALUES (
                OLD.technician_id,
                'تم سحب الطلب ⚠️',
                'الطلب رقم ' || v_readable_id || ' لـ(' || v_service_name || ') تم نقله من جدولك.',
                jsonb_build_object('booking_id', NEW.id, 'status', 'reassigned', 'action_type', 'reassignment')
            );
        END IF;

        INSERT INTO public.notifications (user_id, title, body, metadata)
        VALUES (
            NEW.user_id,
            'تحديث الفني 🔄',
            'تم تعيين فني جديد لطلبك رقم ' || v_readable_id || ' لـ(' || v_service_name || ').',
            jsonb_build_object('booking_id', NEW.id, 'status', NEW.status, 'action_type', 'tech_changed')
        );
    END IF;

    -- ==========================================
    -- ج. تغيير حالات الأوردر الأساسية
    -- ==========================================
    IF v_status_changed THEN
        CASE NEW.status
            WHEN 'assigned' THEN
                v_recipient_id := NEW.technician_id;
                v_title := 'طلب جديد معين لك 🛠️';
                v_body := 'لديك طلب (' || v_service_name || ') جديد برقم ' || v_readable_id || '. يرجى المراجعة.';

            WHEN 'accepted' THEN
                v_recipient_id := NEW.user_id;
                SELECT first_name INTO v_tech_name FROM public.profiles WHERE id = NEW.technician_id;
                v_title := 'تم قبول طلبك ✅';
                v_body := 'الفني ' || COALESCE(v_tech_name, '') || ' قبل طلبك رقم (' || v_readable_id || ') لـ(' || v_service_name || ').';

            WHEN 'on_the_way' THEN
                v_recipient_id := NEW.user_id;
                SELECT first_name INTO v_tech_name FROM public.profiles WHERE id = NEW.technician_id;
                v_title := 'الفني في الطريق 🚗';
                v_body := 'الفني ' || COALESCE(v_tech_name, '') || ' الآن في طريقه إليك لتنفيذ خدمة (' || v_service_name || ').';

            WHEN 'arrived' THEN
                v_recipient_id := NEW.user_id;
                v_title := 'وصل الفني 📍';
                v_body := 'الفني وصل لموقعك الآن لبدء تنفيذ خدمة (' || v_service_name || ').';

            WHEN 'in_progress' THEN
                v_recipient_id := NEW.user_id;
                v_title := 'بدء الخدمة الآن 🚀';
                v_body := 'بدأ العمل الفعلي على طلبك رقم (' || v_readable_id || ') لـ(' || v_service_name || ') الآن.';

            WHEN 'completed' THEN
                v_recipient_id := NEW.user_id;
                v_title := 'تم الانتهاء بنجاح ⭐';
                v_body := 'تم إتمام خدمة (' || v_service_name || ') بنجاح. برقم طلب ' || v_readable_id || '. شكرا لك!';

            WHEN 'cancelled' THEN
                v_recipient_id := CASE 
                    WHEN NEW.cancelled_by_role = 'customer' THEN NEW.technician_id 
                    ELSE NEW.user_id 
                END;
                v_title := 'تم إلغاء الطلب ⚠️';
                v_body := 'تم إلغاء طلب (' || v_service_name || ') رقم ' || v_readable_id || '.';

            WHEN 'failed_no_show' THEN
                v_recipient_id := NEW.user_id;
                v_title := 'نعتذر منك 😔';
                v_body := 'نعتذر لعدم تمكن الفني من الوصول في الموعد لطلبك (' || v_service_name || '). سيتم التواصل معك فوراً.';

            WHEN 'expired' THEN
                v_recipient_id := NEW.user_id;
                v_title := 'تحديث حالة الطلب ⏳';
                v_body := 'انتهت مهلة قبول الطلب (' || v_service_name || '). جاري إعادة التنسيق.';

            ELSE
                v_recipient_id := NULL;
        END CASE;

        -- إرسال الإشعار الرئيسي مع حماية الـ Anti-Duplicate
        IF v_recipient_id IS NOT NULL THEN
            IF NOT EXISTS (
                SELECT 1 FROM public.notifications 
                WHERE user_id = v_recipient_id 
                  AND (metadata->>'booking_id')::UUID = NEW.id
                  AND (metadata->>'status') = NEW.status::TEXT
                  AND created_at > (NOW() - INTERVAL '10 seconds')
            ) THEN
                INSERT INTO public.notifications (user_id, title, body, metadata)
                VALUES (
                    v_recipient_id, v_title, v_body, 
                    jsonb_build_object(
                        'booking_id', NEW.id, 
                        'status', NEW.status, 
                        'action_type', 'status_change', 
                        'readable_id', v_readable_id, 
                        'service_name', v_service_name
                    )
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. إعادة ربط المشغل الوحيد الصحيح بجدول الحجوزات
CREATE TRIGGER tr_on_booking_status_change_notify
AFTER INSERT OR UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.handle_booking_notification();
