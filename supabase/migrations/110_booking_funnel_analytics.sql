-- ==============================================================================
-- Migration: 110_booking_funnel_analytics.sql
-- Description: Phase 2 - Lightweight Booking Funnel Storage, Strict RLS & Security RPCs
--
-- 1. Table: public.booking_funnel_events
--    - Zero-PII, anonymous behavioral funnel storage.
--    - No browser_id / fingerprint, no user_id.
--    - Strict idempotency constraint: UNIQUE(session_id, step_number).
--    - Direct relational linkage to bookings(id) on Step 5 (ON DELETE SET NULL).
--
-- 2. Security & RLS Architecture:
--    - Direct table access REVOKED from anon and authenticated.
--    - SELECT permitted exclusively for authenticated administrators (via public.is_admin()).
--
-- 3. Ingestion RPC: public.record_booking_funnel_step
--    - SECURITY DEFINER with search_path hardening.
--    - Strict input validation (UUID v4 format, step_number 1..5, authoritative event names).
--    - ON CONFLICT DO NOTHING ensures safe idempotency and prevents counter inflation.
--
-- 4. Aggregation RPC: public.get_booking_funnel_stats
--    - SECURITY DEFINER, restricted to administrators.
--    - Authoritative COUNT(DISTINCT session_id) progression calculations.
--    - Zero-division guards on all completion and drop-off rates.
--    - Structured JSON contract ready for admin dashboard consumption.
--
-- Spec Reference: docs_guest/booking_tracking_implementation_plan.md (DEC-07, DEC-08, DEC-09, DEC-11)
-- ==============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Create Funnel Storage Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.booking_funnel_events (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id       TEXT NOT NULL,
    step_number      SMALLINT NOT NULL CHECK (step_number BETWEEN 1 AND 5),
    event_name       TEXT NOT NULL,
    service_id       TEXT,
    service_name     TEXT,
    booking_id       UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    tracking_version TEXT NOT NULL DEFAULT 'v1',
    metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 2. Indexes & Performance Optimization
-- -----------------------------------------------------------------------------
-- Primary idempotency index: guarantees exactly one progression record per session per step
CREATE UNIQUE INDEX IF NOT EXISTS uq_funnel_session_step 
    ON public.booking_funnel_events (session_id, step_number);

-- Time-range query performance for dashboard aggregations
CREATE INDEX IF NOT EXISTS idx_funnel_created_at 
    ON public.booking_funnel_events (created_at DESC);

-- Service filter optimization
CREATE INDEX IF NOT EXISTS idx_funnel_service_created 
    ON public.booking_funnel_events (service_id, created_at DESC) 
    WHERE service_id IS NOT NULL;

-- Reverse linkage lookup from booking to funnel journey
CREATE INDEX IF NOT EXISTS idx_funnel_booking_id 
    ON public.booking_funnel_events (booking_id) 
    WHERE booking_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 3. Row Level Security (RLS) Policies
-- -----------------------------------------------------------------------------
ALTER TABLE public.booking_funnel_events ENABLE ROW LEVEL SECURITY;

-- Revoke all direct table manipulation permissions from public roles
REVOKE ALL ON TABLE public.booking_funnel_events FROM PUBLIC, anon, authenticated;

-- Grant SELECT only to authenticated users (evaluated by RLS policy) and service_role
GRANT SELECT ON TABLE public.booking_funnel_events TO authenticated, service_role;

DROP POLICY IF EXISTS admin_select_funnel_events ON public.booking_funnel_events;
CREATE POLICY admin_select_funnel_events ON public.booking_funnel_events
    FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 4. Ingestion RPC: record_booking_funnel_step (Security Definer)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_booking_funnel_step(
    p_session_id       TEXT,
    p_step_number      SMALLINT,
    p_event_name       TEXT,
    p_service_id       TEXT DEFAULT NULL,
    p_service_name     TEXT DEFAULT NULL,
    p_booking_id       UUID DEFAULT NULL,
    p_metadata         JSONB DEFAULT '{}'::jsonb,
    p_tracking_version TEXT DEFAULT 'v1'
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_safe_metadata   JSONB := '{}'::jsonb;
    v_safe_booking_id UUID := NULL;
BEGIN
    -- Guard 1: Validate session_id format (must be standard UUID string)
    IF p_session_id IS NULL OR TRIM(p_session_id) = '' THEN
        RETURN FALSE;
    END IF;

    IF NOT (p_session_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') THEN
        RETURN FALSE;
    END IF;

    -- Guard 2: Validate step_number range (1 to 5)
    IF p_step_number IS NULL OR p_step_number < 1 OR p_step_number > 5 THEN
        RETURN FALSE;
    END IF;

    -- Guard 3: Validate authoritative event names and exact mapping to step_number
    IF p_event_name IS NULL OR TRIM(p_event_name) = '' THEN
        RETURN FALSE;
    END IF;

    IF (p_step_number = 1 AND p_event_name != 'service_selected') OR
       (p_step_number = 2 AND p_event_name != 'price_calculated') OR
       (p_step_number = 3 AND p_event_name != 'schedule_selected') OR
       (p_step_number = 4 AND p_event_name != 'address_confirmed') OR
       (p_step_number = 5 AND p_event_name != 'booking_created') THEN
        RETURN FALSE;
    END IF;

    -- Guard 4: Sanitize metadata (must be JSON object, max payload 1024 bytes, no arrays/primitives)
    IF p_metadata IS NOT NULL AND jsonb_typeof(p_metadata) = 'object' THEN
        IF octet_length(p_metadata::text) <= 1024 THEN
            v_safe_metadata := p_metadata;
        END IF;
    END IF;

    -- Guard 5: Booking ID linkage is strictly reserved for step 5 (booking_created)
    IF p_step_number = 5 THEN
        v_safe_booking_id := p_booking_id;
    END IF;

    -- Safe Idempotent Insert: Ignores duplicate calls within the same journey
    INSERT INTO public.booking_funnel_events (
        session_id,
        step_number,
        event_name,
        service_id,
        service_name,
        booking_id,
        tracking_version,
        metadata
    ) VALUES (
        TRIM(p_session_id),
        p_step_number,
        TRIM(p_event_name),
        NULLIF(TRIM(p_service_id), ''),
        NULLIF(TRIM(p_service_name), ''),
        v_safe_booking_id,
        COALESCE(NULLIF(TRIM(p_tracking_version), ''), 'v1'),
        v_safe_metadata
    )
    ON CONFLICT (session_id, step_number) DO NOTHING;

    RETURN FOUND;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. Aggregation RPC: get_booking_funnel_stats (Security Definer)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_booking_funnel_stats(
    p_start_date       TIMESTAMPTZ DEFAULT NULL,
    p_end_date         TIMESTAMPTZ DEFAULT NULL,
    p_service_id       TEXT DEFAULT NULL,
    p_tracking_version TEXT DEFAULT 'v1'
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_start_date   TIMESTAMPTZ;
    v_end_date     TIMESTAMPTZ;
    v_s1           BIGINT := 0;
    v_s2           BIGINT := 0;
    v_s3           BIGINT := 0;
    v_s4           BIGINT := 0;
    v_s5           BIGINT := 0;
    v_conv_rate    NUMERIC(5,2) := 0.00;
    v_drop_count_1 BIGINT := 0;
    v_drop_count_2 BIGINT := 0;
    v_drop_count_3 BIGINT := 0;
    v_drop_count_4 BIGINT := 0;
    v_drop_rate_1  NUMERIC(5,2) := 0.00;
    v_drop_rate_2  NUMERIC(5,2) := 0.00;
    v_drop_rate_3  NUMERIC(5,2) := 0.00;
    v_drop_rate_4  NUMERIC(5,2) := 0.00;
    v_comp_rate_1  NUMERIC(5,2) := 0.00;
    v_comp_rate_2  NUMERIC(5,2) := 0.00;
    v_comp_rate_3  NUMERIC(5,2) := 0.00;
    v_comp_rate_4  NUMERIC(5,2) := 0.00;
    v_comp_rate_5  NUMERIC(5,2) := 0.00;
    v_biggest_step INT := NULL;
    v_biggest_name TEXT := NULL;
    v_biggest_rate NUMERIC(5,2) := 0.00;
    v_biggest_drop BIGINT := 0;
    v_res          JSONB;
BEGIN
    -- 1. Strict Administrator Authorization Check
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can access booking funnel analytics.' USING ERRCODE = '42501';
    END IF;

    -- 2. Time-window bounds (default to last 30 days if omitted)
    v_start_date := COALESCE(p_start_date, now() - INTERVAL '30 days');
    v_end_date   := COALESCE(p_end_date, now());

    -- 3. Distinct session count per step
    SELECT
        COUNT(DISTINCT session_id) FILTER (WHERE step_number = 1),
        COUNT(DISTINCT session_id) FILTER (WHERE step_number = 2),
        COUNT(DISTINCT session_id) FILTER (WHERE step_number = 3),
        COUNT(DISTINCT session_id) FILTER (WHERE step_number = 4),
        COUNT(DISTINCT session_id) FILTER (WHERE step_number = 5)
    INTO
        v_s1, v_s2, v_s3, v_s4, v_s5
    FROM public.booking_funnel_events
    WHERE created_at >= v_start_date
      AND created_at <= v_end_date
      AND (p_service_id IS NULL OR TRIM(p_service_id) = '' OR service_id = TRIM(p_service_id))
      AND (p_tracking_version IS NULL OR tracking_version = p_tracking_version);

    -- 4. Conversion & cumulative completion rates with division-by-zero protection
    IF v_s1 > 0 THEN
        v_conv_rate   := ROUND((v_s5::NUMERIC / v_s1::NUMERIC) * 100.0, 2);
        v_comp_rate_1 := 100.00;
        v_comp_rate_2 := ROUND((v_s2::NUMERIC / v_s1::NUMERIC) * 100.0, 2);
        v_comp_rate_3 := ROUND((v_s3::NUMERIC / v_s1::NUMERIC) * 100.0, 2);
        v_comp_rate_4 := ROUND((v_s4::NUMERIC / v_s1::NUMERIC) * 100.0, 2);
        v_comp_rate_5 := ROUND((v_s5::NUMERIC / v_s1::NUMERIC) * 100.0, 2);
    END IF;

    -- 5. Step-to-step drop-offs with zero-division protection
    -- Transition 1 -> 2
    v_drop_count_1 := GREATEST(0, v_s1 - v_s2);
    IF v_s1 > 0 THEN
        v_drop_rate_1 := ROUND((v_drop_count_1::NUMERIC / v_s1::NUMERIC) * 100.0, 2);
    END IF;

    -- Transition 2 -> 3
    v_drop_count_2 := GREATEST(0, v_s2 - v_s3);
    IF v_s2 > 0 THEN
        v_drop_rate_2 := ROUND((v_drop_count_2::NUMERIC / v_s2::NUMERIC) * 100.0, 2);
    END IF;

    -- Transition 3 -> 4
    v_drop_count_3 := GREATEST(0, v_s3 - v_s4);
    IF v_s3 > 0 THEN
        v_drop_rate_3 := ROUND((v_drop_count_3::NUMERIC / v_s3::NUMERIC) * 100.0, 2);
    END IF;

    -- Transition 4 -> 5
    v_drop_count_4 := GREATEST(0, v_s4 - v_s5);
    IF v_s4 > 0 THEN
        v_drop_rate_4 := ROUND((v_drop_count_4::NUMERIC / v_s4::NUMERIC) * 100.0, 2);
    END IF;

    -- 6. Identify biggest drop-off step across transitions
    IF v_s1 > 0 THEN
        v_biggest_step := 1;
        v_biggest_name := 'service_selected';
        v_biggest_rate := v_drop_rate_1;
        v_biggest_drop := v_drop_count_1;

        IF v_drop_rate_2 > v_biggest_rate THEN
            v_biggest_step := 2;
            v_biggest_name := 'price_calculated';
            v_biggest_rate := v_drop_rate_2;
            v_biggest_drop := v_drop_count_2;
        END IF;

        IF v_drop_rate_3 > v_biggest_rate THEN
            v_biggest_step := 3;
            v_biggest_name := 'schedule_selected';
            v_biggest_rate := v_drop_rate_3;
            v_biggest_drop := v_drop_count_3;
        END IF;

        IF v_drop_rate_4 > v_biggest_rate THEN
            v_biggest_step := 4;
            v_biggest_name := 'address_confirmed';
            v_biggest_rate := v_drop_rate_4;
            v_biggest_drop := v_drop_count_4;
        END IF;
    END IF;

    -- 7. Build structured JSON payload for clean consumption
    v_res := jsonb_build_object(
        'summary', jsonb_build_object(
            'total_started', v_s1,
            'total_completed', v_s5,
            'overall_conversion_rate', v_conv_rate,
            'biggest_drop_off_step', v_biggest_step,
            'biggest_drop_off_name', v_biggest_name,
            'biggest_drop_off_rate', v_biggest_rate,
            'biggest_drop_off_count', v_biggest_drop
        ),
        'steps', jsonb_build_array(
            jsonb_build_object(
                'step_number', 1,
                'event_name', 'service_selected',
                'display_name_ar', 'اختيار الخدمة',
                'count', v_s1,
                'completion_rate', v_comp_rate_1,
                'drop_off_count', v_drop_count_1,
                'drop_off_rate', v_drop_rate_1
            ),
            jsonb_build_object(
                'step_number', 2,
                'event_name', 'price_calculated',
                'display_name_ar', 'حساب السعر',
                'count', v_s2,
                'completion_rate', v_comp_rate_2,
                'drop_off_count', v_drop_count_2,
                'drop_off_rate', v_drop_rate_2
            ),
            jsonb_build_object(
                'step_number', 3,
                'event_name', 'schedule_selected',
                'display_name_ar', 'اختيار الموعد',
                'count', v_s3,
                'completion_rate', v_comp_rate_3,
                'drop_off_count', v_drop_count_3,
                'drop_off_rate', v_drop_rate_3
            ),
            jsonb_build_object(
                'step_number', 4,
                'event_name', 'address_confirmed',
                'display_name_ar', 'تأكيد العنوان',
                'count', v_s4,
                'completion_rate', v_comp_rate_4,
                'drop_off_count', v_drop_count_4,
                'drop_off_rate', v_drop_rate_4
            ),
            jsonb_build_object(
                'step_number', 5,
                'event_name', 'booking_created',
                'display_name_ar', 'إتمام الحجز',
                'count', v_s5,
                'completion_rate', v_comp_rate_5,
                'drop_off_count', 0,
                'drop_off_rate', 0.00
            )
        ),
        'filters_applied', jsonb_build_object(
            'start_date', v_start_date,
            'end_date', v_end_date,
            'service_id', p_service_id,
            'tracking_version', p_tracking_version
        )
    );

    RETURN v_res;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. Function Grants
-- -----------------------------------------------------------------------------
-- Safe ingestion callable by anonymous visitors, logged in customers, and backend roles
GRANT EXECUTE ON FUNCTION public.record_booking_funnel_step(TEXT, SMALLINT, TEXT, TEXT, TEXT, UUID, JSONB, TEXT) 
    TO anon, authenticated, service_role;

-- Analytics dashboard retrieval strictly callable by authenticated users (guarded by is_admin)
GRANT EXECUTE ON FUNCTION public.get_booking_funnel_stats(TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT) 
    TO authenticated, service_role;

COMMIT;
