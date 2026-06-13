-- ==============================================================================
-- Fresh Home: Backend Security Hardening Migration (31_backend_security_hardening.sql)
-- Version: 1.0 (Production Ready)
-- Objective: Secure all pricing tables, RPCs, transitions, RLS, and admin panels.
-- ==============================================================================

-- ── 1. HARDEN PRICING TABLES RLS POLICIES ─────────────────────────────────────

-- Enable Row Level Security (RLS) on pricing tables
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pricing_discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pricing_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pricing_governance_audit ENABLE ROW LEVEL SECURITY;

-- pricing_rules policies
DROP POLICY IF EXISTS select_pricing_rules ON public.pricing_rules;
DROP POLICY IF EXISTS all_admin_pricing_rules ON public.pricing_rules;
DROP POLICY IF EXISTS pricing_read_only ON public.pricing_rules;
DROP POLICY IF EXISTS pricing_admin_full_access ON public.pricing_rules;

CREATE POLICY pricing_read_only ON public.pricing_rules
    FOR SELECT TO authenticated USING (true);

CREATE POLICY pricing_admin_full_access ON public.pricing_rules
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- pricing_discounts policies
DROP POLICY IF EXISTS select_pricing_discounts ON public.pricing_discounts;
DROP POLICY IF EXISTS all_admin_pricing_discounts ON public.pricing_discounts;
DROP POLICY IF EXISTS pricing_discounts_read_only ON public.pricing_discounts;
DROP POLICY IF EXISTS pricing_discounts_admin_full_access ON public.pricing_discounts;

CREATE POLICY pricing_discounts_read_only ON public.pricing_discounts
    FOR SELECT TO authenticated USING (true);

CREATE POLICY pricing_discounts_admin_full_access ON public.pricing_discounts
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- pricing_versions policies
DROP POLICY IF EXISTS select_pricing_versions ON public.pricing_versions;
DROP POLICY IF EXISTS all_admin_pricing_versions ON public.pricing_versions;
DROP POLICY IF EXISTS pricing_versions_read_only ON public.pricing_versions;
DROP POLICY IF EXISTS pricing_versions_admin_full_access ON public.pricing_versions;

CREATE POLICY pricing_versions_read_only ON public.pricing_versions
    FOR SELECT TO authenticated USING (true);

CREATE POLICY pricing_versions_admin_full_access ON public.pricing_versions
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- pricing_governance_audit policies
DROP POLICY IF EXISTS select_pricing_governance_audit ON public.pricing_governance_audit;
DROP POLICY IF EXISTS insert_pricing_governance_audit ON public.pricing_governance_audit;
DROP POLICY IF EXISTS pricing_governance_audit_admin_select ON public.pricing_governance_audit;
DROP POLICY IF EXISTS pricing_governance_audit_admin_insert ON public.pricing_governance_audit;

CREATE POLICY pricing_governance_audit_admin_select ON public.pricing_governance_audit
    FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY pricing_governance_audit_admin_insert ON public.pricing_governance_audit
    FOR INSERT TO authenticated WITH CHECK (public.is_admin());


-- ── 2. PREVENT DIRECT BOOKING INSERTS BY STANDARD USERS ───────────────────────

-- Drop direct insertion policy for standard users
DROP POLICY IF EXISTS "Users can create their own bookings" ON public.bookings;


-- ── 3. PRICING INPUTS DYNAMIC VALIDATION SCHEMAS & HELPER ────────────────────

CREATE OR REPLACE FUNCTION public.validate_pricing_inputs(
    p_sub_service_id UUID,
    p_pricing_inputs JSONB
) RETURNS VOID AS $$
DECLARE
    v_price_config JSONB;
    v_method       TEXT;
    v_fields       JSONB;
    v_field        JSONB;
    v_field_id     TEXT;
    v_field_type   TEXT;
    v_required     BOOLEAN;
    v_val          JSONB;
BEGIN
    -- Fetch the sub-service pricing config
    SELECT price_config INTO v_price_config
    FROM public.sub_services
    WHERE id = p_sub_service_id;
    
    IF NOT FOUND OR v_price_config IS NULL THEN
        RAISE EXCEPTION 'الخدمة الفرعية المحددة غير موجودة أو لا تحتوي على إعدادات تسعير' USING ERRCODE = 'P0002';
    END IF;
    
    v_method := v_price_config ->> 'type';
    v_fields := v_price_config -> 'fields';
    
    -- Ensure pricing inputs is a JSON object
    IF p_pricing_inputs IS NULL OR jsonb_typeof(p_pricing_inputs) != 'object' THEN
        RAISE EXCEPTION 'مدخلات التسعير يجب أن تكون كائن JSON صالح' USING ERRCODE = 'P0001';
    END IF;
    
    -- Validate required fields in config
    IF v_fields IS NOT NULL AND jsonb_array_length(v_fields) > 0 THEN
        FOR v_field IN SELECT * FROM jsonb_array_elements(v_fields) LOOP
            v_field_id := v_field ->> 'id';
            v_field_type := v_field ->> 'type';
            v_required := COALESCE((v_field ->> 'required')::BOOLEAN, false);
            
            IF v_required AND NOT (p_pricing_inputs ? v_field_id) THEN
                RAISE EXCEPTION 'الحقل المطلوب % غير موجود في المدخلات', v_field_id USING ERRCODE = 'P0001';
            END IF;
            
            IF p_pricing_inputs ? v_field_id THEN
                v_val := p_pricing_inputs -> v_field_id;
                IF v_field_type = 'number' AND jsonb_typeof(v_val) != 'number' THEN
                    RAISE EXCEPTION 'نوع الحقل % غير صالح: متوقع رقم', v_field_id USING ERRCODE = 'P0001';
                END IF;
                IF v_field_type = 'toggle' AND jsonb_typeof(v_val) != 'boolean' THEN
                    RAISE EXCEPTION 'نوع الحقل % غير صالح: متوقع قيمة منطقية (true/false)', v_field_id USING ERRCODE = 'P0001';
                END IF;
            END IF;
        END LOOP;
    ELSE
        -- Legacy Fallback Validation
        IF v_method = 'per_square_meter' THEN
            IF NOT (p_pricing_inputs ? 'area') THEN
                RAISE EXCEPTION 'المساحة (area) مطلوبة لحساب سعر هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;
            IF jsonb_typeof(p_pricing_inputs -> 'area') != 'number' THEN
                RAISE EXCEPTION 'المساحة (area) يجب أن تكون رقماً' USING ERRCODE = 'P0001';
            END IF;
        ELSIF v_method = 'per_linear_meter' THEN
            IF NOT (p_pricing_inputs ? 'total_linear_meters') AND NOT (p_pricing_inputs ? 'windows') THEN
                RAISE EXCEPTION 'الأطوال الخطية أو أبعاد النوافذ مطلوبة لحساب هذه الخدمة' USING ERRCODE = 'P0001';
            END IF;
            IF p_pricing_inputs ? 'total_linear_meters' AND jsonb_typeof(p_pricing_inputs -> 'total_linear_meters') != 'number' THEN
                RAISE EXCEPTION 'الأطوال الخطية يجب أن تكون رقماً' USING ERRCODE = 'P0001';
            END IF;
            IF p_pricing_inputs ? 'windows' AND jsonb_typeof(p_pricing_inputs -> 'windows') != 'array' THEN
                RAISE EXCEPTION 'بيانات النوافذ (windows) يجب أن تكون مصفوفة' USING ERRCODE = 'P0001';
            END IF;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;


-- Update execute_pricing_pipeline to call validation first
CREATE OR REPLACE FUNCTION public.execute_pricing_pipeline(
    p_sub_service_id UUID,
    p_price_config JSONB,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_context    JSONB;
    v_version_id UUID;
    v_snapshot   JSONB;
    v_rules      JSONB;
    v_discounts  JSONB;
BEGIN
    -- 0. Securely validate pricing inputs schema and types
    PERFORM public.validate_pricing_inputs(p_sub_service_id, p_pricing_inputs);

    -- 1. Autoritatively capture/lock active pricing version
    BEGIN
        v_version_id := public.capture_pricing_version(p_sub_service_id);
        
        -- Load locked snapshot components
        SELECT snapshot INTO v_snapshot
        FROM public.pricing_versions
        WHERE id = v_version_id;
        
        v_rules := v_snapshot -> 'rules';
        v_discounts := v_snapshot -> 'discounts';
    EXCEPTION WHEN OTHERS THEN
        v_version_id := NULL;
        v_rules := NULL;
        v_discounts := NULL;
    END;

    -- 2. Initialize deterministic execution contract context
    v_context := jsonb_build_object(
        'base_price', 0.0,
        'subtotal', 0.0,
        'extra_fees', 0.0,
        'discount', 0.0,
        'applied_rules', '[]'::JSONB,
        'applied_discounts', '[]'::JSONB,
        'selected_options', '[]'::JSONB,
        'execution_trace', '[]'::JSONB,
        'pricing_inputs', COALESCE(p_pricing_inputs, '{}'::JSONB),
        'pricing_version_id', v_version_id
    );

    -- Inject snapshots if successfully locked
    IF v_rules IS NOT NULL THEN
        v_context := v_context || jsonb_build_object(
            'snapshot_rules', v_rules,
            'snapshot_discounts', v_discounts
        );
    END IF;

    -- 3. Stage 1: Base Pricing
    v_context := public.stage_1_calculate_base_pricing(p_sub_service_id, p_price_config, v_context);

    -- 4. Stage 2: Relational Conditional Rules
    v_context := public.stage_2_apply_conditional_rules(p_sub_service_id, v_context);

    -- 5. Stage 3: Options / Add-ons
    v_context := public.stage_3_apply_options(p_sub_service_id, p_price_config, v_context);

    -- 6. Stage 4: Dynamic stackable discounts
    v_context := public.stage_4_apply_discounts(p_sub_service_id, v_context);

    -- 7. Stage 5: Finalization and Formatter mapping
    v_context := public.stage_5_finalize_pricing(p_sub_service_id, v_context);

    RETURN v_context;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ── 4. SECURE ATOMIC BOOKING TRANSACTION RPC ──────────────────────────────────

DROP FUNCTION IF EXISTS public.create_atomic_booking(UUID, UUID, UUID, DATE, JSONB, JSONB, JSONB, TEXT, TEXT[], TIME, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id          UUID,
    p_sub_service_id   UUID,
    p_technician_id    UUID,
    p_scheduled_day    DATE,
    p_address_snapshot JSONB,
    p_service_snapshot JSONB,
    p_pricing_inputs   JSONB,
    p_contact_name     TEXT DEFAULT 'Client',
    p_contact_phones   TEXT[] DEFAULT '{}'::TEXT[],
    p_start_time_slot  TIME DEFAULT '09:00',
    p_actor_id         UUID DEFAULT NULL,
    p_actor_role       TEXT DEFAULT 'admin'
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
BEGIN
    -- Verify booking creation authorization (Standard user must only book for themselves)
    IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
        IF p_user_id != auth.uid() THEN
            RAISE EXCEPTION 'Unauthorized: Users can only create bookings for themselves.' USING ERRCODE = '42501';
        END IF;
    END IF;

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

    -- Load price configuration
    SELECT price_config INTO v_price_config
    FROM public.sub_services
    WHERE id = p_sub_service_id;

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

    INSERT INTO public.bookings (
        user_id, technician_id, service_id, scheduled_day, start_time_slot,
        address_snapshot, service_snapshot, price_snapshot,
        pricing_inputs, pricing_version_id,
        contact_name, contact_phones,
        status
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, v_price_snapshot,
        COALESCE(p_pricing_inputs, '{}'::JSONB), v_version_id,
        p_contact_name, p_contact_phones,
        'created'::public.order_status_v2
    ) RETURNING id INTO v_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    PERFORM public.transition_booking(
        v_booking_id,
        'assigned'::public.order_status_v2,
        COALESCE(p_actor_id, p_user_id),
        p_actor_role,
        'BOOKING_CREATION',
        'تم إنشاء الحجز والتحقق من السعر وتثبيت النسخة الأرشيفية بنجاح.'
    );

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


-- ── 5. SECURE LIFECYCLE BOOKING TRANSITION GATEKEEPER ─────────────────────────

-- Drop transition_booking with all potential argument signatures and schemas to avoid return type conflicts
DROP FUNCTION IF EXISTS public.transition_booking(uuid, public.order_status_v2, uuid, text, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.transition_booking(uuid, order_status_v2, uuid, text, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, public.order_status_v2, uuid, text, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, order_status_v2, uuid, text, text, text, jsonb) CASCADE;

-- Drop overloaded versions just in case
DROP FUNCTION IF EXISTS public.transition_booking(uuid, public.order_status_v2, uuid, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.transition_booking(uuid, order_status_v2, uuid, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, public.order_status_v2, uuid, text, text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, order_status_v2, uuid, text, text, text, uuid) CASCADE;

DROP FUNCTION IF EXISTS public.transition_booking(uuid, public.order_status_v2, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.transition_booking(uuid, order_status_v2, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, public.order_status_v2, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS transition_booking(uuid, order_status_v2, uuid, text, text, text) CASCADE;
CREATE OR REPLACE FUNCTION public.transition_booking(
    p_booking_id    UUID,
    p_new_status    public.order_status_v2,
    p_actor_id      UUID,
    p_actor_role    TEXT,
    p_reason_code   TEXT DEFAULT NULL,
    p_notes         TEXT DEFAULT NULL,
    p_metadata      JSONB DEFAULT '{}'::JSONB
)
RETURNS public.bookings AS $$
DECLARE
    v_old_status public.order_status_v2;
    v_booking    public.bookings;
    v_cond_code  TEXT;
    v_is_valid   BOOLEAN := FALSE;
    v_force      BOOLEAN := COALESCE((p_metadata->>'force_override')::BOOLEAN, FALSE);
    v_trusted    BOOLEAN;
    v_db_role    TEXT;
BEGIN
    -- Check if this is a trusted internal call
    v_trusted := COALESCE(NULLIF(current_setting('app.trusted_internal_call', true), ''), 'false') = 'true';

    -- Secure actor and role mapping
    IF auth.uid() IS NOT NULL AND NOT v_trusted THEN
        p_actor_id := auth.uid();
        
        SELECT r.name INTO v_db_role
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_actor_id
        ORDER BY CASE r.name
            WHEN 'admin' THEN 1
            WHEN 'technician' THEN 2
            WHEN 'client' THEN 3
            ELSE 4
        END ASC
        LIMIT 1;
        
        IF v_db_role IS NULL THEN
            RAISE EXCEPTION 'Unauthorized: User role not configured.' USING ERRCODE = '42501';
        END IF;
        
        IF v_db_role = 'client' THEN
            p_actor_role := 'customer';
        ELSE
            p_actor_role := v_db_role;
        END IF;
    END IF;

    -- Administrative safety check: prevent standard users from spoofing admin roles
    IF p_actor_role = 'admin' AND NOT v_trusted AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Actor is not an administrator.' USING ERRCODE = '42501';
    END IF;

    -- 1. Fetch and Lock for safety (Race Condition Protection)
    SELECT status INTO v_old_status FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'BOOKING_NOT_FOUND'; END IF;

    -- 2. Idempotency
    IF v_old_status = p_new_status THEN 
        SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
        RETURN v_booking; 
    END IF;

    -- 3. Terminal State Check
    IF v_old_status IN ('completed', 'cancelled', 'expired', 'failed_no_show') AND NOT (p_actor_role = 'admin' AND v_force) THEN
        RAISE EXCEPTION 'TERMINAL_STATE_LOCKED';
    END IF;

    -- 4. Transition Validation
    IF p_actor_role = 'admin' AND v_force THEN
        IF p_reason_code IS NULL THEN RAISE EXCEPTION 'ADMIN_OVERRIDE_REQUIRES_REASON'; END IF;
        v_is_valid := TRUE;
    ELSE
        SELECT condition_code INTO v_cond_code
        FROM public.state_transitions
        WHERE from_status = v_old_status 
          AND to_status   = p_new_status 
          AND allowed_role = p_actor_role
          AND is_active   = true;
        
        IF v_cond_code IS NOT NULL OR FOUND THEN
            v_is_valid := public.evaluate_transition_condition(v_cond_code, p_metadata);
        END IF;
    END IF;

    IF NOT v_is_valid THEN
        RAISE EXCEPTION 'INVALID_TRANSITION' USING DETAIL = format('%s -> %s by %s', v_old_status, p_new_status, p_actor_role);
    END IF;

    -- 5. Atomic Update with Concurrency Guard
    UPDATE public.bookings
    SET 
        status = p_new_status,
        updated_at = NOW(),
        -- Logic for Technician Rejection / Reassignment
        technician_id = CASE WHEN p_new_status = 'pending' THEN NULL ELSE technician_id END,
        assigned_at   = CASE 
            WHEN p_new_status = 'assigned' THEN NOW() 
            WHEN p_new_status = 'pending'  THEN NULL 
            ELSE assigned_at 
        END,
        accepted_at   = CASE WHEN p_new_status = 'accepted'    THEN NOW() ELSE accepted_at END,
        dispatched_at = CASE WHEN p_new_status = 'on_the_way'  THEN NOW() ELSE dispatched_at END,
        arrived_at    = CASE WHEN p_new_status = 'arrived'     THEN NOW() ELSE arrived_at END,
        started_at    = CASE WHEN p_new_status = 'in_progress' THEN NOW() ELSE started_at END,
        completed_at  = CASE WHEN p_new_status = 'completed'   THEN NOW() ELSE completed_at END,
        cancelled_at  = CASE WHEN p_new_status = 'cancelled'   THEN NOW() ELSE cancelled_at END,
        cancellation_reason_code = COALESCE(p_reason_code, cancellation_reason_code),
        cancelled_by_role        = CASE WHEN p_new_status = 'cancelled' THEN p_actor_role ELSE cancelled_by_role END,
        is_critical   = FALSE,
        critical_reason = NULL
    WHERE id = p_booking_id AND status = v_old_status -- Strict Concurrency Guard
    RETURNING * INTO v_booking;

    IF NOT FOUND THEN RAISE EXCEPTION 'CONCURRENT_UPDATE_DETECTED'; END IF;

    -- 6. Audit Event Log
    INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
    VALUES (
        p_booking_id, 
        CASE WHEN v_force THEN 'FORCE_OVERRIDE' ELSE 'STATUS_CHANGE' END, 
        p_actor_id, 
        p_actor_role, 
        jsonb_build_object(
            'from', v_old_status, 
            'to', p_new_status, 
            'notes', p_notes, 
            'reason', p_reason_code,
            'metadata', p_metadata
        )
    );

    RETURN v_booking;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


-- ── 6. SECURE CLIENT AUDITED UPDATES ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.customer_update_booking_schedule(
    p_booking_id    UUID,
    p_new_day       DATE,
    p_new_time_slot TIME,
    p_actor_id      UUID
) RETURNS VOID AS $$
DECLARE
    v_old_day       DATE;
    v_old_time      TIME;
    v_status        public.order_status_v2;
    v_tech_id       UUID;
    v_service_id    UUID;
    v_booking_user_id UUID;
    v_is_available  BOOLEAN;
BEGIN
    -- A. Fetch current state and lock
    SELECT scheduled_day, start_time_slot, status, technician_id, service_id, user_id 
    INTO v_old_day, v_old_time, v_status, v_tech_id, v_service_id, v_booking_user_id
    FROM public.bookings WHERE id = p_booking_id FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'الحجز غير موجود'; END IF;

    -- B. Enforce Authentication & Authorization
    IF auth.uid() IS NOT NULL THEN
        p_actor_id := auth.uid();
        IF NOT (public.is_admin() OR v_booking_user_id = auth.uid()) THEN
            RAISE EXCEPTION 'Unauthorized: Access to update this booking is restricted.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- C. Business Validation: Status Check
    IF v_status NOT IN ('created', 'assigned', 'accepted', 'ready', 'pending') THEN
        RAISE EXCEPTION 'لا يمكن تعديل الموعد بعد بدء التنفيذ أو إلغاء الحجز';
    END IF;

    -- D. Availability/Capacity Check
    SELECT EXISTS (
        SELECT 1 FROM public.get_available_technicians(v_service_id, p_new_day)
        WHERE technician_id = v_tech_id
    ) INTO v_is_available;

    IF NOT v_is_available THEN
        RAISE EXCEPTION 'الفني غير متاح في الموعد الجديد أو تم بلوغ الحد الأقصى للسعة';
    END IF;

    -- E. Atomic Update
    UPDATE public.bookings
    SET scheduled_day = p_new_day,
        start_time_slot = p_new_time_slot,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- F. Detailed Audit Trail
    INSERT INTO public.booking_events (
        booking_id, event_type, actor_id, actor_role, metadata
    ) VALUES (
        p_booking_id,
        'SCHEDULE_UPDATE',
        p_actor_id,
        CASE WHEN p_actor_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.user_roles ur JOIN public.roles r ON ur.role_id = r.id 
            WHERE ur.user_id = p_actor_id AND r.name = 'admin'
        ) THEN 'admin' ELSE 'customer' END,
        jsonb_build_object(
            'old_schedule', jsonb_build_object('day', v_old_day, 'time', v_old_time),
            'new_schedule', jsonb_build_object('day', p_new_day, 'time', p_new_time_slot)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION public.customer_update_booking_address(
    p_booking_id       UUID,
    p_address_snapshot JSONB,
    p_contact_snapshot JSONB,
    p_actor_id         UUID
) RETURNS VOID AS $$
DECLARE
    v_old_address JSONB;
    v_old_contact JSONB;
    v_status      public.order_status_v2;
    v_booking_user_id UUID;
BEGIN
    -- A. Fetch current state and lock
    SELECT address_snapshot, service_snapshot->'contact', status, user_id
    INTO v_old_address, v_old_contact, v_status, v_booking_user_id
    FROM public.bookings WHERE id = p_booking_id FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'الحجز غير موجود'; END IF;

    -- B. Enforce Authentication & Authorization
    IF auth.uid() IS NOT NULL THEN
        p_actor_id := auth.uid();
        IF NOT (public.is_admin() OR v_booking_user_id = auth.uid()) THEN
            RAISE EXCEPTION 'Unauthorized: Access to update this booking is restricted.' USING ERRCODE = '42501';
        END IF;
    END IF;

    -- C. Business Validation
    IF v_status NOT IN ('created', 'assigned', 'accepted', 'ready', 'pending') THEN
        RAISE EXCEPTION 'لا يمكن تعديل العنوان بعد وصول الفني أو بدء العمل';
    END IF;

    -- D. Atomic Update
    UPDATE public.bookings
    SET address_snapshot = p_address_snapshot,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- E. Detailed Audit Trail
    INSERT INTO public.booking_events (
        booking_id, event_type, actor_id, actor_role, metadata
    ) VALUES (
        p_booking_id,
        'ADDRESS_UPDATE',
        p_actor_id,
        CASE WHEN p_actor_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.user_roles ur JOIN public.roles r ON ur.role_id = r.id 
            WHERE ur.user_id = p_actor_id AND r.name = 'admin'
        ) THEN 'admin' ELSE 'customer' END,
        jsonb_build_object(
            'old_address', v_old_address,
            'new_address', p_address_snapshot
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ── 7. SECURE INTERNAL ADMIN LOGIC FUNCTIONS ────────────────────────────────

DROP FUNCTION IF EXISTS public.admin_reschedule_booking_atomic(UUID, DATE, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id   UUID,
    p_new_date     DATE,
    p_admin_id     UUID,
    p_reason       TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_tech_id      UUID;
    v_service_id   UUID;
    v_pool_id      UUID;
    v_max_cap      INTEGER;
    v_current_load INTEGER;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reschedule bookings.' USING ERRCODE = '42501';
    END IF;

    -- 1. Get booking details
    SELECT technician_id, service_id INTO v_tech_id, v_service_id
    FROM public.bookings
    WHERE id = p_booking_id;

    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'Booking not found or not assigned' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Resolve Capacity Pool
    SELECT capacity_pool_id INTO v_pool_id
    FROM public.technician_skills
    WHERE technician_id  = v_tech_id
      AND sub_service_id = v_service_id
      AND is_active      = true;

    -- 3. Locking & Verification
    v_lock_key_1 := hashtext(v_tech_id::TEXT || v_pool_id::TEXT);
    v_lock_key_2 := hashtext(p_new_date::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    SELECT max_daily_capacity INTO v_max_cap FROM public.capacity_pools WHERE id = v_pool_id;
    
    SELECT COUNT(*) INTO v_current_load
    FROM public.bookings b
    WHERE b.technician_id = v_tech_id
      AND b.service_id    = v_service_id
      AND b.scheduled_day::DATE = p_new_date
      AND b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
      AND b.id != p_booking_id;

    IF v_current_load >= v_max_cap THEN
        RAISE EXCEPTION 'Capacity full for this technician on the new date.' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Update Booking & Log Event
    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        p_admin_id,
        'admin',
        'ADMIN_RESCHEDULE',
        COALESCE(p_reason, 'Order rescheduled to ' || p_new_date::TEXT)
    );

    UPDATE public.bookings 
    SET scheduled_day = p_new_date
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


DROP FUNCTION IF EXISTS public.admin_reassign_booking(UUID, UUID, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_reassign_booking(
    p_booking_id       UUID,
    p_new_technician_id UUID,
    p_admin_id         UUID,
    p_reason           TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_service_id   UUID;
    v_pool_id      UUID;
    v_max_cap      INTEGER;
    v_current_load INTEGER;
    v_scheduled_day DATE;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reassign bookings.' USING ERRCODE = '42501';
    END IF;

    -- 1. Get booking details
    SELECT service_id, scheduled_day::DATE INTO v_service_id, v_scheduled_day
    FROM public.bookings
    WHERE id = p_booking_id;

    -- 2. Resolve Capacity Pool for NEW technician
    SELECT capacity_pool_id INTO v_pool_id
    FROM public.technician_skills
    WHERE technician_id  = p_new_technician_id
      AND sub_service_id = v_service_id
      AND is_active      = true;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'New technician does not have active skill for this service.' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Locking & Verification
    v_lock_key_1 := hashtext(p_new_technician_id::TEXT || v_pool_id::TEXT);
    v_lock_key_2 := hashtext(v_scheduled_day::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    SELECT max_daily_capacity INTO v_max_cap FROM public.capacity_pools WHERE id = v_pool_id;
    
    SELECT COUNT(*) INTO v_current_load
    FROM public.bookings b
    WHERE b.technician_id   = p_new_technician_id
      AND b.scheduled_day::DATE = v_scheduled_day
      AND b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician');

    IF v_current_load >= v_max_cap THEN
        RAISE EXCEPTION 'Target technician is at full capacity for this day.' USING ERRCODE = 'P0002';
    END IF;

    -- 4. Update Booking & Log Event
    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        p_admin_id,
        'admin',
        'ADMIN_REASSIGN',
        COALESCE(p_reason, 'Technician reassigned by admin')
    );

    UPDATE public.bookings 
    SET technician_id = p_new_technician_id
    WHERE id = p_booking_id;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


DROP FUNCTION IF EXISTS public.admin_force_status_update(UUID, public.order_status_v2, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_force_status_update(
    p_booking_id   UUID,
    p_new_status   public.order_status_v2,
    p_admin_id     UUID,
    p_notes        TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can force status updates.' USING ERRCODE = '42501';
    END IF;

    PERFORM set_config('app.trusted_internal_call', 'true', true);
    PERFORM public.transition_booking(
        p_booking_id,
        p_new_status,
        p_admin_id,
        'admin',
        'ADMIN_FORCE_UPDATE',
        COALESCE(p_notes, 'Manual status override by administrator'),
        jsonb_build_object('force_override', true)
    );
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


DROP FUNCTION IF EXISTS public.get_fleet_capacity_dashboard(DATE, DATE, UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.get_fleet_capacity_dashboard(
    p_start_date DATE,
    p_end_date   DATE,
    p_main_service_id UUID DEFAULT NULL
) RETURNS TABLE (
    service_id             UUID,
    service_title         JSONB,
    target_date            DATE,
    total_technicians      BIGINT,
    total_capacity        BIGINT,
    total_booked          BIGINT,
    available_capacity    BIGINT,
    utilization_percentage DECIMAL
) AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the fleet capacity dashboard.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT d.day::DATE AS target_date 
        FROM generate_series(p_start_date, p_end_date, '1 day'::INTERVAL) AS d(day)
    ),
    service_list AS (
        SELECT ss.id, ss.title, ss.main_service_id
        FROM public.sub_services ss
        WHERE (p_main_service_id IS NULL OR ss.main_service_id = p_main_service_id)
    ),
    tech_capabilities AS (
        SELECT
            ds.target_date,
            sl.id AS sub_service_id,
            ts.technician_id,
            ts.capacity_pool_id,
            CASE
                WHEN co.is_blocked = TRUE THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_capacity
        FROM date_series ds
        CROSS JOIN service_list sl
        JOIN public.technician_skills ts ON ts.sub_service_id = sl.id
        JOIN public.capacity_pools cp    ON cp.id = ts.capacity_pool_id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = ts.capacity_pool_id
              AND co_inner.technician_id = ts.technician_id
              AND co_inner.override_date = ds.target_date
            ORDER BY co_inner.override_date DESC, co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE ts.is_active = true
    ),
    service_load AS (
        SELECT
            (b.scheduled_day AT TIME ZONE 'UTC')::DATE AS target_date,
            b.service_id,
            COUNT(b.id) AS booked_count
        FROM public.bookings b
        WHERE b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
          AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE BETWEEN p_start_date AND p_end_date
        GROUP BY 1, 2
    )
    SELECT
        sl.id,
        sl.title,
        ds.target_date,
        COUNT(DISTINCT tc.technician_id) FILTER (WHERE tc.effective_capacity > 0),
        SUM(tc.effective_capacity)::BIGINT,
        COALESCE(l.booked_count, 0)::BIGINT,
        (SUM(tc.effective_capacity) - COALESCE(l.booked_count, 0))::BIGINT,
        ROUND(
            (COALESCE(l.booked_count, 0)::DECIMAL / NULLIF(SUM(tc.effective_capacity), 0)) * 100, 
            2
        )
    FROM date_series ds
    CROSS JOIN service_list sl
    LEFT JOIN tech_capabilities tc ON tc.target_date = ds.target_date AND tc.sub_service_id = sl.id
    LEFT JOIN service_load l      ON l.target_date = ds.target_date AND l.service_id = sl.id
    GROUP BY sl.id, sl.title, ds.target_date
    ORDER BY ds.target_date, sl.title->>'en';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


DROP FUNCTION IF EXISTS public.get_technician_capacity_report(DATE, UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.get_technician_capacity_report(
    p_date DATE,
    p_sub_service_id UUID DEFAULT NULL
) RETURNS TABLE (
    technician_id    UUID,
    first_name       TEXT,
    last_name        TEXT,
    pool_title       TEXT,
    effective_cap    INTEGER,
    current_load     BIGINT,
    is_blocked       BOOLEAN,
    status           TEXT
) AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the technician capacity report.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH tech_stats AS (
        SELECT
            tp.user_id,
            pr.first_name,
            pr.last_name,
            cp.title AS pool_title,
            cp.id AS pool_id,
            CASE
                WHEN co.is_blocked = TRUE THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_capacity,
            COALESCE(co.is_blocked, false) AS blocked_flag,
            (
                SELECT COUNT(*)
                FROM public.bookings b
                JOIN public.technician_skills s ON s.sub_service_id = b.service_id
                WHERE s.capacity_pool_id = cp.id
                  AND b.scheduled_day::DATE = p_date
                  AND (b.technician_id = tp.user_id OR b.technician_id IS NULL)
                  AND b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
            ) AS load_count
        FROM public.technician_profiles tp
        JOIN public.profiles pr ON pr.id = tp.user_id
        JOIN public.capacity_pools cp ON cp.technician_id = tp.user_id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = cp.id
              AND co_inner.technician_id = tp.user_id
              AND co_inner.override_date = p_date
            ORDER BY co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE (p_sub_service_id IS NULL OR EXISTS (
            SELECT 1 FROM public.technician_skills ts 
            WHERE ts.technician_id = tp.user_id AND ts.sub_service_id = p_sub_service_id
        ))
    )
    SELECT
        t.user_id,
        t.first_name,
        t.last_name,
        t.pool_title,
        t.effective_capacity,
        t.load_count::BIGINT,
        t.blocked_flag,
        CASE
            WHEN t.blocked_flag THEN 'blocked'
            WHEN t.load_count > t.effective_capacity THEN 'overloaded'
            WHEN t.load_count = t.effective_capacity THEN 'full'
            WHEN t.load_count = 0 THEN 'idle'
            ELSE 'healthy'
        END
    FROM tech_stats t
    ORDER BY t.load_count DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ── 8. SECURE API CLIENT-FACING ADMIN FLEET OPERATIONS RPCS ──────────────────

-- get_fleet_capacity_dashboard (API facing overload)
DROP FUNCTION IF EXISTS public.get_fleet_capacity_dashboard(DATE, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.get_fleet_capacity_dashboard(
    p_start_date  DATE,
    p_days_ahead  INTEGER DEFAULT 14
)
RETURNS TABLE (
    target_date             DATE,
    total_capacity          INTEGER,
    total_booked            INTEGER,
    available_capacity      INTEGER,
    utilization_percentage  NUMERIC
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the fleet capacity dashboard.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(
            p_start_date,
            p_start_date + (p_days_ahead - 1)::INTEGER,
            INTERVAL '1 day'
        )::DATE AS day
    ),
    tech_capacity AS (
        SELECT
            d.day,
            cp.technician_id,
            COALESCE(
                CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
                cp.max_daily_capacity
            ) AS effective_capacity
        FROM date_series d
        CROSS JOIN public.capacity_pools cp
        LEFT JOIN public.capacity_overrides co
            ON co.pool_id = cp.id
           AND co.technician_id = cp.technician_id
           AND co.override_date = d.day
    ),
    daily_capacity AS (
        SELECT
            day,
            SUM(effective_capacity) AS total_cap
        FROM tech_capacity
        GROUP BY day
    ),
    daily_bookings AS (
        SELECT
            scheduled_day::DATE AS day,
            COUNT(*) AS booked
        FROM public.bookings
        WHERE status NOT IN (
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician'
        )
          AND scheduled_day::DATE BETWEEN p_start_date AND p_start_date + (p_days_ahead - 1)::INTEGER
        GROUP BY scheduled_day::DATE
    )
    SELECT
        d.day                                                   AS target_date,
        COALESCE(dc.total_cap, 0)::INTEGER                     AS total_capacity,
        COALESCE(db.booked, 0)::INTEGER                        AS total_booked,
        GREATEST(0, COALESCE(dc.total_cap, 0) - COALESCE(db.booked, 0))::INTEGER AS available_capacity,
        CASE
            WHEN COALESCE(dc.total_cap, 0) = 0 THEN 0
            ELSE ROUND((COALESCE(db.booked, 0)::NUMERIC / dc.total_cap::NUMERIC) * 100, 1)
        END AS utilization_percentage
    FROM date_series d
    LEFT JOIN daily_capacity dc ON dc.day = d.day
    LEFT JOIN daily_bookings db ON db.day = d.day
    ORDER BY d.day;
END;
$$;


-- get_technician_capacity_report (with main_service_id)
DROP FUNCTION IF EXISTS public.get_technician_capacity_report(DATE) CASCADE;

CREATE OR REPLACE FUNCTION public.get_technician_capacity_report(
    p_target_date  DATE
)
RETURNS TABLE (
    technician_id           UUID,
    technician_name         TEXT,
    main_service_id         UUID,
    workload                INTEGER,
    capacity                INTEGER,
    utilization_percentage  NUMERIC,
    status                  TEXT
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can view the technician capacity report.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH tech_capacity AS (
        SELECT
            cp.technician_id,
            COALESCE(
                CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
                cp.max_daily_capacity
            ) AS effective_capacity,
            COALESCE(co.is_blocked, FALSE) AS is_blocked
        FROM public.capacity_pools cp
        LEFT JOIN public.capacity_overrides co
            ON co.pool_id = cp.id
           AND co.technician_id = cp.technician_id
           AND co.override_date = p_target_date
    ),
    agg_capacity AS (
        SELECT
            technician_id,
            SUM(effective_capacity)::INTEGER AS total_cap,
            BOOL_OR(is_blocked) AS is_blocked
        FROM tech_capacity
        GROUP BY technician_id
    ),
    daily_bookings AS (
        SELECT
            technician_id,
            COUNT(*)::INTEGER AS booked
        FROM public.bookings
        WHERE status NOT IN (
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician'
        )
          AND scheduled_day::DATE = p_target_date
          AND technician_id IS NOT NULL
        GROUP BY technician_id
    )
    SELECT
        ac.technician_id,
        p.first_name || ' ' || p.last_name                     AS technician_name,
        tp.main_service_id,
        COALESCE(db.booked, 0)                                  AS workload,
        ac.total_cap                                            AS capacity,
        CASE
            WHEN ac.total_cap = 0 THEN 100
            ELSE ROUND((COALESCE(db.booked, 0)::NUMERIC / ac.total_cap::NUMERIC) * 100, 1)
        END                                                     AS utilization_percentage,
        CASE
            WHEN ac.is_blocked                              THEN 'blocked'
            WHEN ac.total_cap = 0                           THEN 'blocked'
            WHEN COALESCE(db.booked, 0) = 0                THEN 'idle'
            WHEN COALESCE(db.booked, 0) >= ac.total_cap    THEN 'full'
            WHEN COALESCE(db.booked, 0)::NUMERIC / ac.total_cap::NUMERIC >= 0.7 THEN 'healthy'
            ELSE 'idle'
        END                                                     AS status
    FROM agg_capacity ac
    JOIN public.profiles p ON p.id = ac.technician_id
    LEFT JOIN public.technician_profiles tp ON tp.user_id = ac.technician_id
    LEFT JOIN daily_bookings db ON db.technician_id = ac.technician_id
    ORDER BY utilization_percentage DESC;
END;
$$;


-- admin_reschedule_booking_atomic (API facing overload)
DROP FUNCTION IF EXISTS public.admin_reschedule_booking_atomic(UUID, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_reschedule_booking_atomic(
    p_booking_id  UUID,
    p_new_date    DATE
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
AS $$
DECLARE
    v_booking          public.bookings;
    v_tech_id          UUID;
    v_pool_id          UUID;
    v_cap              INTEGER;
    v_booked           INTEGER;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reschedule bookings.' USING ERRCODE = '42501';
    END IF;

    -- Fetch booking
    SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found: %', p_booking_id USING ERRCODE = 'P0001';
    END IF;

    v_tech_id := v_booking.technician_id;

    -- Verify technician is assigned
    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'Booking has no assigned technician.' USING ERRCODE = 'P0002';
    END IF;

    -- Get the technician's capacity pool for this service
    SELECT cp.id INTO v_pool_id
    FROM public.capacity_pools cp
    JOIN public.technician_skills ts
        ON ts.capacity_pool_id = cp.id AND ts.technician_id = cp.technician_id
    WHERE cp.technician_id = v_tech_id
      AND ts.sub_service_id = v_booking.service_id
    LIMIT 1;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'Technician capacity pool not found.' USING ERRCODE = 'P0003';
    END IF;

    -- Effective capacity for new date
    SELECT COALESCE(
        CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
        cp.max_daily_capacity
    ) INTO v_cap
    FROM public.capacity_pools cp
    LEFT JOIN public.capacity_overrides co
        ON co.pool_id = cp.id AND co.technician_id = cp.technician_id
       AND co.override_date = p_new_date
    WHERE cp.id = v_pool_id;

    -- Count existing bookings on new date for this technician
    SELECT COUNT(*)::INTEGER INTO v_booked
    FROM public.bookings
    WHERE technician_id = v_tech_id
      AND scheduled_day::DATE = p_new_date
      AND id != p_booking_id
      AND status NOT IN (
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician'
      );

    IF v_booked >= v_cap THEN
        RAISE EXCEPTION 'Technician is at full capacity on %. Cannot reschedule.', p_new_date
            USING ERRCODE = 'P0004';
    END IF;

    -- Perform the rescheduling
    UPDATE public.bookings
    SET scheduled_day = p_new_date
    WHERE id = p_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    -- Transition booking status via lifecycle gatekeeper
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        auth.uid(),
        'admin',
        'ADMIN_RESCHEDULE',
        'Admin rescheduled booking to ' || p_new_date::TEXT,
        jsonb_build_object('force_override', true)
    );
END;
$$;


-- admin_reassign_booking (API facing overload)
DROP FUNCTION IF EXISTS public.admin_reassign_booking(UUID, UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_reassign_booking(
    p_booking_id        UUID,
    p_new_technician_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
AS $$
DECLARE
    v_booking       public.bookings;
    v_old_tech_id   UUID;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can reassign bookings.' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found: %', p_booking_id USING ERRCODE = 'P0001';
    END IF;

    -- Verify new technician exists
    IF NOT EXISTS (
        SELECT 1 FROM public.technician_profiles WHERE user_id = p_new_technician_id
    ) THEN
        RAISE EXCEPTION 'Target technician profile not found.' USING ERRCODE = 'P0002';
    END IF;

    v_old_tech_id := v_booking.technician_id;

    -- Perform reassignment
    UPDATE public.bookings
    SET technician_id = p_new_technician_id
    WHERE id = p_booking_id;

    -- Set session flag to signal trusted database internal state machine action
    PERFORM set_config('app.trusted_internal_call', 'true', true);

    -- Transition booking status via lifecycle gatekeeper
    PERFORM public.transition_booking(
        p_booking_id,
        'assigned'::public.order_status_v2,
        auth.uid(),
        'admin',
        'ADMIN_REASSIGN',
        'Admin manually reassigned technician',
        jsonb_build_object('force_override', true)
    );

    -- Log into assignment_logs
    INSERT INTO public.assignment_logs (
        booking_id, new_technician_id, previous_technician_id, assigned_by, reason
    ) VALUES (
        p_booking_id,
        p_new_technician_id,
        v_old_tech_id,
        'admin',
        'Admin manual reassignment'
    );
END;
$$;


-- admin_force_status_update (API facing overload)
DROP FUNCTION IF EXISTS public.admin_force_status_update(UUID, DATE, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.admin_force_status_update(
    p_technician_id  UUID,
    p_target_date    DATE,
    p_new_status     TEXT
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
AS $$
DECLARE
    v_pool_id       UUID;
    v_max_cap       INTEGER;
    v_new_capacity  INTEGER;
    v_is_blocked    BOOLEAN;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can force capacity status updates.' USING ERRCODE = '42501';
    END IF;

    -- Get the first capacity pool for this technician
    SELECT id, max_daily_capacity INTO v_pool_id, v_max_cap
    FROM public.capacity_pools
    WHERE technician_id = p_technician_id
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_pool_id IS NULL THEN
        RAISE EXCEPTION 'No capacity pool found for technician %', p_technician_id
            USING ERRCODE = 'P0001';
    END IF;

    -- Map status string to override values
    CASE p_new_status
        WHEN 'blocked' THEN
            v_is_blocked   := TRUE;
            v_new_capacity := NULL;
        WHEN 'idle' THEN
            v_is_blocked   := FALSE;
            v_new_capacity := v_max_cap;
        WHEN 'full' THEN
            v_is_blocked   := FALSE;
            v_new_capacity := 0;
        WHEN 'healthy' THEN
            v_is_blocked   := FALSE;
            v_new_capacity := GREATEST(1, (v_max_cap * 0.5)::INTEGER);
        ELSE
            RAISE EXCEPTION 'Invalid status: %. Valid: blocked, idle, healthy, full', p_new_status
                USING ERRCODE = 'P0002';
    END CASE;

    -- Upsert the override
    INSERT INTO public.capacity_overrides (
        pool_id, technician_id, override_date, new_capacity, is_blocked, reason
    ) VALUES (
        v_pool_id,
        p_technician_id,
        p_target_date,
        v_new_capacity,
        v_is_blocked,
        'Admin force status: ' || p_new_status
    )
    ON CONFLICT (technician_id, pool_id, override_date)
    DO UPDATE SET
        new_capacity = EXCLUDED.new_capacity,
        is_blocked   = EXCLUDED.is_blocked,
        reason       = EXCLUDED.reason,
        updated_at   = NOW();
END;
$$;


-- ── 9. SECURE GRANULAR CAPACITY POOL BREAKDOWN RPC ────────────────────────────

DROP FUNCTION IF EXISTS public.get_technician_daily_pool_breakdown(UUID, DATE);

CREATE OR REPLACE FUNCTION public.get_technician_daily_pool_breakdown(
    p_technician_id UUID,
    p_date          DATE
) RETURNS TABLE (
    pool_id          UUID,
    pool_title       TEXT,
    max_capacity     INTEGER,
    current_load     INTEGER,
    is_blocked       BOOLEAN,
    override_capacity INTEGER,
    is_override      BOOLEAN,
    slot_mask        TEXT
) AS $$
BEGIN
    -- Enforce access check: Only admins or the technician themselves can view their pool breakdown
    IF auth.uid() IS NOT NULL AND NOT (public.is_admin() OR auth.uid() = p_technician_id) THEN
        RAISE EXCEPTION 'Unauthorized: Access to this technician capacity breakdown is restricted.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT 
        cp.id,
        cp.title,
        cp.max_daily_capacity,
        (
            SELECT COUNT(*)::INTEGER
            FROM public.bookings b
            JOIN public.technician_skills ts ON ts.sub_service_id = b.service_id
            WHERE ts.capacity_pool_id = cp.id
              AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE = p_date
              AND (b.technician_id = p_technician_id OR b.technician_id IS NULL)
              AND b.status NOT IN ('cancelled_by_customer', 'cancelled_by_admin', 'cancelled_by_technician')
        ) AS current_load,
        COALESCE(co.is_blocked, false) AS is_blocked,
        co.new_capacity AS override_capacity,
        (co.pool_id IS NOT NULL) AS is_override,
        co.slot_mask
    FROM public.capacity_pools cp
    LEFT JOIN LATERAL (
        SELECT co_inner.pool_id, co_inner.is_blocked, co_inner.new_capacity, co_inner.slot_mask
        FROM public.capacity_overrides co_inner
        WHERE co_inner.pool_id       = cp.id
          AND co_inner.technician_id = p_technician_id
          AND co_inner.override_date = p_date
        ORDER BY co_inner.created_at DESC
        LIMIT 1
    ) co ON TRUE
    WHERE cp.technician_id = p_technician_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ── 10. REPLAY AND SIMULATE PRICING POLICIES ──────────────────────────────────

CREATE OR REPLACE FUNCTION public.replay_booking_pricing(
    p_booking_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_booking_record RECORD;
    v_version_record RECORD;
    v_price_config   JSONB;
    v_context        JSONB;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can replay booking pricing.' USING ERRCODE = '42501';
    END IF;

    -- 1. Fetch booking record
    SELECT service_id, price_snapshot, pricing_inputs, pricing_version_id
    INTO v_booking_record
    FROM public.bookings
    WHERE id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'الحجز المحدد غير موجود' USING ERRCODE = 'P0002';
    END IF;

    -- 2. Fetch locked version snapshot
    SELECT snapshot INTO v_version_record
    FROM public.pricing_versions
    WHERE id = v_booking_record.pricing_version_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'نسخة التسعير المؤرشفة لهذا الحجز غير موجودة' USING ERRCODE = 'P0002';
    END IF;

    -- 3. Initialize pricing context with locked snapshot components
    v_context := jsonb_build_object(
        'base_price', 0.0,
        'subtotal', 0.0,
        'extra_fees', 0.0,
        'discount', 0.0,
        'applied_rules', '[]'::JSONB,
        'applied_discounts', '[]'::JSONB,
        'selected_options', '[]'::JSONB,
        'execution_trace', '[]'::JSONB,
        'pricing_inputs', COALESCE(v_booking_record.pricing_inputs, '{}'::JSONB),
        'pricing_version_id', v_booking_record.pricing_version_id,
        'snapshot_rules', v_version_record -> 'rules',
        'snapshot_discounts', v_version_record -> 'discounts'
    );

    -- 4. Execute pipeline stages directly from snapshot
    v_price_config := v_version_record -> 'price_config';
    v_context := public.stage_1_calculate_base_pricing(v_booking_record.service_id, v_price_config, v_context);
    v_context := public.stage_2_apply_conditional_rules(v_booking_record.service_id, v_context);
    v_context := public.stage_3_apply_options(v_booking_record.service_id, v_price_config, v_context);
    v_context := public.stage_4_apply_discounts(v_booking_record.service_id, v_context);
    v_context := public.stage_5_finalize_pricing(v_booking_record.service_id, v_context);

    -- Return full replay ledger comparison report
    RETURN jsonb_build_object(
        'booking_id', p_booking_id,
        'original_snapshot', v_booking_record.price_snapshot,
        'replayed_snapshot', v_context,
        'is_match', (v_booking_record.price_snapshot ->> 'total')::NUMERIC = (v_context ->> 'total')::NUMERIC
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE OR REPLACE FUNCTION public.simulate_pricing_pipeline(
    p_sub_service_id UUID,
    p_price_config JSONB,
    p_rules JSONB,
    p_discounts JSONB,
    p_pricing_inputs JSONB
) RETURNS JSONB AS $$
DECLARE
    v_context JSONB;
BEGIN
    -- Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can simulate pricing pipelines.' USING ERRCODE = '42501';
    END IF;

    -- 1. Initialize context contract containing simulation overrides
    v_context := jsonb_build_object(
        'base_price', 0.0,
        'subtotal', 0.0,
        'extra_fees', 0.0,
        'discount', 0.0,
        'applied_rules', '[]'::JSONB,
        'applied_discounts', '[]'::JSONB,
        'selected_options', '[]'::JSONB,
        'execution_trace', '[]'::JSONB,
        'pricing_inputs', COALESCE(p_pricing_inputs, '{}'::JSONB),
        'snapshot_rules', COALESCE(p_rules, '[]'::JSONB),
        'snapshot_discounts', COALESCE(p_discounts, '[]'::JSONB),
        'is_simulation', true
    );

    -- 2. Execute pipeline stages directly using simulation inputs
    v_context := public.stage_1_calculate_base_pricing(p_sub_service_id, p_price_config, v_context);
    v_context := public.stage_2_apply_conditional_rules(p_sub_service_id, v_context);
    v_context := public.stage_3_apply_options(p_sub_service_id, p_price_config, v_context);
    v_context := public.stage_4_apply_discounts(p_sub_service_id, v_context);
    v_context := public.stage_5_finalize_pricing(p_sub_service_id, v_context);

    RETURN v_context;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ── 11. PRICING GOVERNANCE AUDIT SYSTEM ───────────────────────────────────────

-- Create Governance Audit Table if not present
DROP TABLE IF EXISTS public.pricing_governance_audit CASCADE;
CREATE TABLE public.pricing_governance_audit (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_service_id     UUID, -- Reference to specific service/sub_service
    rule_id            UUID, -- Reference to pricing_rules
    discount_id        UUID, -- Reference to pricing_discounts
    action             TEXT NOT NULL, -- 'INSERT' | 'UPDATE' | 'DELETE'
    actor_id           UUID, -- Optionally references auth.users if populated
    before_state       JSONB,
    after_state        JSONB,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Comments on the table
COMMENT ON TABLE public.pricing_governance_audit IS 'Audits admin structural pricing rules and discounts configuration adjustments.';

-- Enable RLS on audit table
ALTER TABLE public.pricing_governance_audit ENABLE ROW LEVEL SECURITY;

-- pricing_governance_audit policies (Drop and recreate)
DROP POLICY IF EXISTS pricing_governance_audit_admin_select ON public.pricing_governance_audit;
DROP POLICY IF EXISTS pricing_governance_audit_admin_insert ON public.pricing_governance_audit;

CREATE POLICY pricing_governance_audit_admin_select ON public.pricing_governance_audit
    FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY pricing_governance_audit_admin_insert ON public.pricing_governance_audit
    FOR INSERT TO authenticated WITH CHECK (public.is_admin());

-- Trigger function to automatically log changes
CREATE OR REPLACE FUNCTION public.fn_audit_pricing_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_action TEXT;
    v_before JSONB := NULL;
    v_after  JSONB := NULL;
    v_sub_service_id UUID := NULL;
    v_rule_id UUID := NULL;
    v_discount_id UUID := NULL;
BEGIN
    v_action := TG_OP;
    
    IF TG_TABLE_NAME = 'pricing_rules' THEN
        IF v_action = 'INSERT' THEN
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_rule_id := NEW.id;
        ELSIF v_action = 'UPDATE' THEN
            v_before := to_jsonb(OLD);
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_rule_id := NEW.id;
        ELSIF v_action = 'DELETE' THEN
            v_before := to_jsonb(OLD);
            v_sub_service_id := OLD.sub_service_id;
            v_rule_id := OLD.id;
        END IF;
    ELSIF TG_TABLE_NAME = 'pricing_discounts' THEN
        IF v_action = 'INSERT' THEN
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_discount_id := NEW.id;
        ELSIF v_action = 'UPDATE' THEN
            v_before := to_jsonb(OLD);
            v_after := to_jsonb(NEW);
            v_sub_service_id := NEW.sub_service_id;
            v_discount_id := NEW.id;
        ELSIF v_action = 'DELETE' THEN
            v_before := to_jsonb(OLD);
            v_sub_service_id := OLD.sub_service_id;
            v_discount_id := OLD.id;
        END IF;
    END IF;
    
    INSERT INTO public.pricing_governance_audit (
        sub_service_id, rule_id, discount_id, action, actor_id, before_state, after_state
    ) VALUES (
        v_sub_service_id, v_rule_id, v_discount_id, v_action, auth.uid(), v_before, v_after
    );
    
    IF v_action = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach Triggers
DROP TRIGGER IF EXISTS trg_audit_pricing_rules ON public.pricing_rules;
CREATE TRIGGER trg_audit_pricing_rules
AFTER INSERT OR UPDATE OR DELETE ON public.pricing_rules
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_pricing_changes();

DROP TRIGGER IF EXISTS trg_audit_pricing_discounts ON public.pricing_discounts;
CREATE TRIGGER trg_audit_pricing_discounts
AFTER INSERT OR UPDATE OR DELETE ON public.pricing_discounts
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_pricing_changes();

