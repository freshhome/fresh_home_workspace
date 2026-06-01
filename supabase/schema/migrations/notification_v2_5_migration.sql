-- ==============================================================================
-- MIGRATION: Notifications System v2.5
-- Run this entire script in Supabase SQL Editor.
-- It is fully idempotent (safe to run multiple times).
-- ==============================================================================

-- STEP 1: Upgrade the deduplication helper function
CREATE OR REPLACE FUNCTION public.insert_notification_if_new(
    p_user_id       UUID,
    p_title         TEXT,
    p_body          TEXT,
    p_booking_id    UUID,
    p_status        TEXT,
    p_action_type   TEXT DEFAULT 'status_change'
)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications
        WHERE user_id = p_user_id
          AND (metadata->>'booking_id')::UUID = p_booking_id
          AND metadata->>'status' = p_status
    ) THEN
        INSERT INTO public.notifications (user_id, title, body, metadata)
        VALUES (
            p_user_id,
            p_title,
            p_body,
            jsonb_build_object(
                'booking_id',   p_booking_id,
                'status',       p_status,
                'action_type',  p_action_type
            )
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 2: Replace the main trigger function (v2.5)
CREATE OR REPLACE FUNCTION public.handle_booking_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_readable_id   TEXT;
    v_cancelled_by  TEXT;
BEGIN
    IF (OLD.status IS NOT DISTINCT FROM NEW.status) THEN
        RETURN NEW;
    END IF;

    v_readable_id  := COALESCE(NEW.readable_id, NEW.id::TEXT);
    v_cancelled_by := COALESCE(NEW.cancelled_by_role, 'unknown');

    CASE NEW.status::TEXT

        WHEN 'assigned' THEN
            IF NEW.technician_id IS NOT NULL THEN
                PERFORM public.insert_notification_if_new(
                    NEW.technician_id,
                    'طلب جديد معين لك',
                    'تم تعيين طلب جديد رقم (' || v_readable_id || ') لك. يرجى المراجعة والقبول.',
                    NEW.id, 'assigned'
                );
            END IF;

        WHEN 'accepted' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'تم قبول طلبك ✅',
                'الفني قبل طلبك رقم (' || v_readable_id || ') وهو الآن في جدول أعماله.',
                NEW.id, 'accepted'
            );

        WHEN 'on_the_way' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '🚗 الفني في الطريق إليك',
                'الفني الآن في طريقه لموقعك لتنفيذ الطلب رقم (' || v_readable_id || ').',
                NEW.id, 'on_the_way'
            );

        WHEN 'arrived' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '📍 الفني وصل لموقعك',
                'وصل الفني للعنوان المحدد لتنفيذ طلبك رقم (' || v_readable_id || '). يرجى الاستعداد لاستقباله.',
                NEW.id, 'arrived'
            );

        WHEN 'in_progress' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '⚙️ بدء الخدمة',
                'بدأ الفني في العمل على طلبك رقم (' || v_readable_id || ') الآن.',
                NEW.id, 'in_progress'
            );

        WHEN 'completed' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '🎉 تم الانتهاء من الخدمة',
                'تم إتمام الطلب رقم (' || v_readable_id || ') بنجاح. شكراً لاستخدامك فريش هوم!',
                NEW.id, 'completed'
            );

        WHEN 'cancelled' THEN
            IF v_cancelled_by = 'customer' THEN
                IF NEW.technician_id IS NOT NULL THEN
                    PERFORM public.insert_notification_if_new(
                        NEW.technician_id,
                        '❌ تم إلغاء الطلب من قِبل العميل',
                        'قام العميل بإلغاء الطلب رقم (' || v_readable_id || ').',
                        NEW.id, 'cancelled'
                    );
                END IF;
            ELSIF v_cancelled_by = 'technician' THEN
                PERFORM public.insert_notification_if_new(
                    NEW.user_id,
                    'نعتذر — اعتذار الفني',
                    'نعتذر، لم يتمكن الفني من تنفيذ طلبك رقم (' || v_readable_id || '). سيتم التواصل معك لإعادة الجدولة.',
                    NEW.id, 'cancelled'
                );
            ELSE
                IF NEW.technician_id IS NOT NULL THEN
                    PERFORM public.insert_notification_if_new(
                        NEW.technician_id,
                        'تم إلغاء الطلب',
                        'تم إلغاء الطلب رقم (' || v_readable_id || ') من قِبل الإدارة.',
                        NEW.id, 'cancelled'
                    );
                END IF;
                PERFORM public.insert_notification_if_new(
                    NEW.user_id,
                    'تم إلغاء طلبك',
                    'نعتذر، تم إلغاء الطلب رقم (' || v_readable_id || '). سيتم التواصل معك في أقرب وقت.',
                    NEW.id, 'cancelled'
                );
            END IF;

        WHEN 'failed_no_show' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'تعذّر تنفيذ الخدمة',
                'لم يتمكن الفني من الوصول لموقعك لتنفيذ الطلب رقم (' || v_readable_id || '). سيتواصل معك فريق الدعم.',
                NEW.id, 'failed_no_show'
            );

        WHEN 'expired' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'انتهت صلاحية الطلب',
                'انتهت صلاحية طلبك رقم (' || v_readable_id || ') دون تعيين فني. يرجى التواصل مع الدعم لإعادة الحجز.',
                NEW.id, 'expired'
            );

        ELSE
            NULL;
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 3: Re-attach trigger (idempotent)
DROP TRIGGER IF EXISTS tr_on_booking_status_change_notify ON public.bookings;
CREATE TRIGGER tr_on_booking_status_change_notify
AFTER UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.handle_booking_notification();

-- STEP 4: Verify (optional, shows current trigger)
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
  AND trigger_schema = 'public';
