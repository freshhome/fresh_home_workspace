-- ==============================================================================
-- Migration: 101_enforce_cairo_giza_coverage.sql
-- Description: Enforce geographic service coverage guard (Cairo & Giza only) in create_atomic_booking
--              and create service_expansion_leads table for capturing out-of-coverage requests.
-- ==============================================================================

BEGIN;

-- 1. Create service_expansion_leads table
CREATE TABLE IF NOT EXISTS public.service_expansion_leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    governorate TEXT NOT NULL,
    city TEXT,
    notes TEXT,
    source TEXT DEFAULT 'booking_flow',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Phone number sanity check constraint
ALTER TABLE public.service_expansion_leads DROP CONSTRAINT IF EXISTS chk_expansion_lead_phone;
ALTER TABLE public.service_expansion_leads ADD CONSTRAINT chk_expansion_lead_phone
    CHECK (length(trim(phone_number)) >= 8 AND length(phone_number) <= 30);

-- Enable RLS
ALTER TABLE public.service_expansion_leads ENABLE ROW LEVEL SECURITY;

-- Allow anonymous and authenticated visitors to submit expansion leads
DROP POLICY IF EXISTS "Allow public to submit expansion leads" ON public.service_expansion_leads;
CREATE POLICY "Allow public to submit expansion leads"
ON public.service_expansion_leads
FOR INSERT
WITH CHECK (true);

-- Allow admins to view all expansion leads
DROP POLICY IF EXISTS "Allow admin to view expansion leads" ON public.service_expansion_leads;
CREATE POLICY "Allow admin to view expansion leads"
ON public.service_expansion_leads
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur 
        JOIN public.roles r ON ur.role_id = r.id 
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- Grant appropriate permissions
GRANT INSERT ON public.service_expansion_leads TO anon, authenticated, service_role;
GRANT SELECT ON public.service_expansion_leads TO authenticated, service_role;


-- 2. Update public.create_atomic_booking to enforce Cairo & Giza coverage guard
CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id                UUID,
    p_sub_service_id         TEXT,
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
    v_governorate    TEXT;
BEGIN
    -- Verify booking creation authorization (Standard user must only book for themselves)
    IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
        IF p_user_id != auth.uid() THEN
            RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- Enforce Geographic Coverage Guard (Cairo & Giza Only)
    v_governorate := TRIM(COALESCE(p_address_snapshot ->> 'governorate', ''));
    IF v_governorate NOT IN ('القاهرة', 'الجيزة') THEN
        RAISE EXCEPTION 'عذراً، خدمات فريش هوم متاحة حالياً داخل محافظتي القاهرة والجيزة فقط.' USING ERRCODE = 'P0020';
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
        whatsapp_confirmation_token,
        payment_method
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, v_price_snapshot,
        COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2,
        p_is_whatsapp_confirmed,
        CASE WHEN NOT p_is_whatsapp_confirmed THEN NOW() + (v_expiry_minutes || ' minutes')::interval ELSE NULL END,
        gen_random_uuid(),
        COALESCE(p_pricing_inputs ->> 'payment_method', 'cash')
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

GRANT EXECUTE ON FUNCTION public.create_atomic_booking(
    UUID, TEXT, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT, BOOLEAN
) TO anon, authenticated, service_role;

COMMIT;
