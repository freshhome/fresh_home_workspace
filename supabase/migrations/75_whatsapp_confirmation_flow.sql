-- Migration ID: 75_whatsapp_confirmation_flow
-- Description: Add WhatsApp confirmation flow for unauthenticated/guest bookings, new system_settings table, RLS tweaks, and trigger updates.

BEGIN;

-- 1. ADD COLUMNS TO public.bookings TABLE
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS is_whatsapp_confirmed BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS whatsapp_confirmation_expires_at TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS whatsapp_confirmation_token UUID DEFAULT gen_random_uuid();

-- Create index for faster scanning of unconfirmed bookings
CREATE INDEX IF NOT EXISTS idx_bookings_whatsapp_unconfirmed 
ON public.bookings (is_whatsapp_confirmed, whatsapp_confirmation_expires_at) 
WHERE is_whatsapp_confirmed = false;

-- 2. CREATE public.system_settings TABLE
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- Seed WhatsApp default configuration
INSERT INTO public.system_settings (key, value, description)
VALUES (
    'whatsapp_settings',
    '{
        "business_number": "+201000000000",
        "expiry_minutes": 60,
        "enabled_for_guests": true,
        "api_endpoint": "https://api.whatsapp.com/v1/messages",
        "api_token": "mock_token_placeholder"
    }'::jsonb,
    'إعدادات تأكيد حجوزات واتساب وإرسال الرسائل للزوار'
) ON CONFLICT (key) DO NOTHING;

-- Enable RLS on public.system_settings
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for public.system_settings
DROP POLICY IF EXISTS "Admins have full access on system_settings" ON public.system_settings;
CREATE POLICY "Admins have full access on system_settings" ON public.system_settings
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

DROP POLICY IF EXISTS "Public select access on system_settings" ON public.system_settings;
CREATE POLICY "Public select access on system_settings" ON public.system_settings
FOR SELECT USING (true);

-- 3. UPDATE RLS POLICIES FOR TECHNICIANS ON public.bookings
-- Technicians should not see or update bookings that are not WhatsApp confirmed yet

DROP POLICY IF EXISTS "Technicians can view their assigned bookings" ON public.bookings;
CREATE POLICY "Technicians can view their assigned bookings" ON public.bookings
FOR SELECT USING (
    auth.uid() = technician_id 
    AND is_whatsapp_confirmed = true
);

DROP POLICY IF EXISTS "Technicians can update their assigned bookings" ON public.bookings;
CREATE POLICY "Technicians can update their assigned bookings" ON public.bookings
FOR UPDATE USING (
    auth.uid() = technician_id 
    AND is_whatsapp_confirmed = true
) WITH CHECK (
    auth.uid() = technician_id 
    AND is_whatsapp_confirmed = true
);

-- 4. SEED TRANSITION ENGINE TO ALLOW SYSTEM CANCELLATION FROM ASSIGNED STATUS
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, condition_code)
VALUES 
('assigned', 'cancelled', 'system', NULL)
ON CONFLICT (from_status, to_status, allowed_role) DO NOTHING;

-- 5. RE-DEFINE public.create_atomic_booking WITH SUPPORT FOR p_is_whatsapp_confirmed
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT, BOOLEAN) CASCADE;

CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id                UUID,
    p_sub_service_id         UUID,
    p_technician_id          UUID,
    p_scheduled_day          DATE,
    p_address_snapshot       JSONB,
    p_service_snapshot       JSONB,
    p_pricing_inputs         JSONB,
    p_contact_name           TEXT DEFAULT 'Client',
    p_contact_phones         TEXT[] DEFAULT '{}'::TEXT[],
    p_start_time_slot        TIME DEFAULT '09:00',
    p_actor_id               UUID DEFAULT NULL,
    p_actor_role             TEXT DEFAULT 'admin',
    p_is_whatsapp_confirmed  BOOLEAN DEFAULT true
) RETURNS UUID AS $$
DECLARE
    v_tech_id        UUID;
    v_booking_id     UUID;
    v_lock_key_1     INT;
    v_lock_key_2     INT;
    v_pipeline_res   JSONB;
    v_price_snapshot JSONB;
    v_price_config   JSONB;
    v_version_id     UUID;
    v_is_bookable    BOOLEAN;
    v_expiry_minutes INT;
BEGIN
    -- Verify booking creation authorization (Standard user must only book for themselves)
    IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
        IF p_user_id != auth.uid() THEN
            RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- Resolve technician (Auto-assign if not specified)
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

    v_lock_key_1 := hashtext(v_tech_id::TEXT);
    v_lock_key_2 := hashtext(p_scheduled_day::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    -- Load price configuration and verify it is bookable
    SELECT price_config, is_bookable INTO v_price_config, v_is_bookable
    FROM public.services
    WHERE id = p_sub_service_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الخدمة المحددة غير موجودة' USING ERRCODE = 'P0002';
    END IF;

    IF NOT v_is_bookable THEN
        RAISE EXCEPTION 'لا يمكن حجز فئة أو قسم غير قابل للحجز' USING ERRCODE = 'P0009';
    END IF;

    -- Calculate price authoritatively via deterministic execution contract pipeline
    v_pipeline_res := public.execute_pricing_pipeline(p_sub_service_id, v_price_config, p_pricing_inputs);

    -- Extract version_id and formatted totals snapshot
    v_version_id := (v_pipeline_res -> 'metadata' ->> 'pricing_version_id')::UUID;
    v_price_snapshot := jsonb_build_object(
        'basePrice', (v_pipeline_res ->> 'basePrice')::NUMERIC,
        'extraFees', (v_pipeline_res ->> 'extraFees')::NUMERIC,
        'discount', (v_pipeline_res ->> 'discount')::NUMERIC,
        'total', (v_pipeline_res ->> 'total')::NUMERIC,
        'metadata', v_pipeline_res -> 'metadata'
    );

    -- Load confirmation expiry settings
    SELECT COALESCE((value->>'expiry_minutes')::integer, 60) INTO v_expiry_minutes
    FROM public.system_settings
    WHERE key = 'whatsapp_settings';

    INSERT INTO public.bookings (
        user_id, technician_id, service_id, scheduled_day, start_time_slot,
        address_snapshot, service_snapshot, price_snapshot,
        pricing_inputs, pricing_version_id,
        contact_name, contact_phones,
        status,
        is_whatsapp_confirmed,
        whatsapp_confirmation_expires_at,
        whatsapp_confirmation_token
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, v_price_snapshot,
        COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2,
        p_is_whatsapp_confirmed,
        CASE WHEN NOT p_is_whatsapp_confirmed THEN NOW() + (v_expiry_minutes || ' minutes')::interval ELSE NULL END,
        gen_random_uuid()
    ) RETURNING id INTO v_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    -- Transition to assigned state via official state machine
    PERFORM public.transition_booking(
        v_booking_id,
        'assigned'::public.order_status_v2,
        COALESCE(p_actor_id, p_user_id),
        p_actor_role,
        'BOOKING_CREATION',
        'تم إنشاء الحجز وتخصيص الفني، في انتظار التأكيد عبر واتساب.'
    );

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 6. UPDATE handle_booking_notification TRIGGER FUNCTION TO RESPECT is_whatsapp_confirmed
CREATE OR REPLACE FUNCTION public.handle_booking_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_readable_id   TEXT;
    v_cancelled_by  TEXT;
BEGIN
    -- Only trigger when status changes for UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Allow trigger if status changes, OR if is_whatsapp_confirmed goes from false to true
        IF (OLD.status IS NOT DISTINCT FROM NEW.status) 
           AND NOT (OLD.is_whatsapp_confirmed = false AND NEW.is_whatsapp_confirmed = true) THEN
            RETURN NEW;
        END IF;
    END IF;

    -- Exit early if booking is not yet WhatsApp confirmed
    IF NOT NEW.is_whatsapp_confirmed THEN
        RETURN NEW;
    END IF;

    v_readable_id  := COALESCE(NEW.readable_id, NEW.id::TEXT);
    v_cancelled_by := COALESCE(NEW.cancelled_by_role, 'unknown');

    CASE NEW.status::TEXT

        -- ── CREATED ───────────────────────────────────────────────────────
        WHEN 'created' THEN
            -- Notify customer that booking was successful
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'تم تأكيد حجزك بنجاح ✨',
                'سعداء باختيارك فريش هوم! تم استلام طلبك رقم (' || v_readable_id || ') بنجاح وجاري مراجعته.',
                NEW.id, 'created'
            );

        -- ── ASSIGNED ──────────────────────────────────────────────────────
        WHEN 'assigned' THEN
            -- If this was a direct insert as assigned (or newly confirmed), notify the customer too
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'تم تأكيد حجزك بنجاح ✨',
                'سعداء باختيارك فريش هوم! تم استلام طلبك رقم (' || v_readable_id || ') بنجاح وتم تعيين فني لخدمتك.',
                NEW.id, 'created'
            );

            -- Notify technician of new assignment
            IF NEW.technician_id IS NOT NULL THEN
                PERFORM public.insert_notification_if_new(
                    NEW.technician_id,
                    '🌟 طلب جديد مسند إليك',
                    'تم تكليفك بمهمة عمل جديدة (طلب رقم: ' || v_readable_id || '). يرجى مراجعة التفاصيل وتأكيد الاستلام.',
                    NEW.id, 'assigned'
                );
            END IF;

        -- ── ACCEPTED ──────────────────────────────────────────────────────
        WHEN 'accepted' THEN
            -- Notify customer
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'تم قبول طلبك ✅',
                'الفني قبل طلبك رقم (' || v_readable_id || ') وهو الآن في جدول أعماله.',
                NEW.id, 'accepted'
            );

        -- ── ON THE WAY ────────────────────────────────────────────────────
        WHEN 'on_the_way' THEN
            -- Notify customer
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '🚗 الفني في الطريق إليك',
                'الفني الآن في طريقه لموقعك لتنفيذ الطلب رقم (' || v_readable_id || ').',
                NEW.id, 'on_the_way'
            );

        -- ── ARRIVED ───────────────────────────────────────────────────────
        WHEN 'arrived' THEN
            -- Notify customer
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '📍 الفني وصل لموقعك',
                'وصل الفني للعنوان المحدد لتنفيذ طلبك رقم (' || v_readable_id || '). يرجى الاستعداد لاستقباله.',
                NEW.id, 'arrived'
            );

        -- ── IN PROGRESS ───────────────────────────────────────────────────
        WHEN 'in_progress' THEN
            -- Notify customer
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '⚙️ بدء الخدمة',
                'بدأ الفني في العمل على طلبك رقم (' || v_readable_id || ') الآن.',
                NEW.id, 'in_progress'
            );

        -- ── COMPLETED ─────────────────────────────────────────────────────
        WHEN 'completed' THEN
            -- Notify customer
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                '🎉 تم الانتهاء من الخدمة',
                'تم إتمام الطلب رقم (' || v_readable_id || ') بنجاح. شكراً لاستخدامك فريش هوم!',
                NEW.id, 'completed'
            );

        -- ── CANCELLED ─────────────────────────────────────────────────────
        WHEN 'cancelled' THEN
            IF v_cancelled_by = 'customer' THEN
                -- Notify technician that customer cancelled
                IF NEW.technician_id IS NOT NULL THEN
                    PERFORM public.insert_notification_if_new(
                        NEW.technician_id,
                        '❌ تم إلغاء الطلب من قِبل العميل',
                        'قام العميل بإلغاء الطلب رقم (' || v_readable_id || ').',
                        NEW.id, 'cancelled'
                    );
                END IF;
            ELSIF v_cancelled_by = 'technician' THEN
                -- Notify customer that technician declined
                PERFORM public.insert_notification_if_new(
                    NEW.user_id,
                    'نعتذر — اعتذار الفني',
                    'نعتذر، لم يتمكن الفني من تنفيذ طلبك رقم (' || v_readable_id || '). سيتم التواصل معك لإعادة الجدولة.',
                    NEW.id, 'cancelled'
                );
            ELSE
                -- Admin or System cancelled: notify both parties
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

        -- ── FAILED NO SHOW ────────────────────────────────────────────────
        WHEN 'failed_no_show' THEN
            PERFORM public.insert_notification_if_new(
                NEW.user_id,
                'تعذّر تنفيذ الخدمة',
                'لم يتمكن الفني من الوصول لموقعك لتنفيذ الطلب رقم (' || v_readable_id || '). سيتواصل معك فريق الدعم.',
                NEW.id, 'failed_no_show'
            );

        -- ── EXPIRED ───────────────────────────────────────────────────────
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

-- Re-attach trigger if not done (it will reuse existing tr_on_booking_status_change_notify)

-- 7. CREATE public.confirm_whatsapp_booking FUNCTION
CREATE OR REPLACE FUNCTION public.confirm_whatsapp_booking(
    p_booking_id UUID,
    p_token      UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_booking public.bookings;
BEGIN
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id AND whatsapp_confirmation_token = p_token;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'رابط التأكيد غير صالح أو منتهي الصلاحية.' USING ERRCODE = 'P0002';
    END IF;

    IF v_booking.is_whatsapp_confirmed THEN
        RETURN TRUE;
    END IF;

    -- Update is_whatsapp_confirmed and clear expiry
    UPDATE public.bookings
    SET 
        is_whatsapp_confirmed = true,
        whatsapp_confirmation_expires_at = NULL,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- Insert event in log
    INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
    VALUES (
        p_booking_id,
        'WHATSAPP_CONFIRMED',
        NULL,
        'customer',
        '{"method": "whatsapp_link"}'::jsonb
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 8. CREATE whatsapp expiry cron function
CREATE OR REPLACE FUNCTION public.check_whatsapp_confirmation_expiry()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN 
        SELECT id FROM public.bookings
        WHERE is_whatsapp_confirmed = false 
          AND status = 'assigned'::public.order_status_v2
          AND whatsapp_confirmation_expires_at < NOW()
    LOOP
        BEGIN
            -- Call the official state machine
            PERFORM public.transition_booking(
                v_rec.id,
                'cancelled'::public.order_status_v2,
                NULL::UUID,
                'system',
                'WHATSAPP_CONFIRMATION_TIMEOUT',
                'تم إلغاء الطلب تلقائياً لعدم التأكيد عبر واتساب خلال المهلة المقررة.'
            );
            
            -- Clear expires_at
            UPDATE public.bookings 
            SET whatsapp_confirmation_expires_at = NULL 
            WHERE id = v_rec.id;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'check_whatsapp_confirmation_expiry failed for booking %: %', v_rec.id, SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule job using pg_cron (runs every 5 minutes)
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'fresh-home-whatsapp-confirmation-expiry';
SELECT cron.schedule(
    'fresh-home-whatsapp-confirmation-expiry',
    '*/5 * * * *',
    $$ SELECT public.check_whatsapp_confirmation_expiry(); $$
);

COMMIT;
