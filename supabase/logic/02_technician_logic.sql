-- [ignoring loop detection]
-- ==============================================================================
-- Fresh Home: Master Assignment & Booking Engine (v4.0 - FINAL)
-- ==============================================================================

-- 0. Ensure contact_name and contact_phones columns exist in bookings table
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS contact_name TEXT DEFAULT 'Client',
ADD COLUMN IF NOT EXISTS contact_phones TEXT[] DEFAULT '{}'::TEXT[];

-- 1. get_available_technicians
CREATE OR REPLACE FUNCTION public.get_available_technicians(
    p_sub_service_id UUID,
    p_date           DATE
) RETURNS TABLE (
    technician_id   UUID,
    first_name      TEXT,
    last_name       TEXT,
    avatar_url      TEXT,
    rating          DECIMAL,
    current_load    BIGINT,
    max_capacity    INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH pool_mapping AS (
        SELECT
            ts.technician_id,
            ts.capacity_pool_id,
            cp.max_daily_capacity
        FROM public.technician_skills ts
        JOIN public.capacity_pools cp ON ts.capacity_pool_id = cp.id
        WHERE ts.sub_service_id = p_sub_service_id
          AND ts.is_active = true
    ),
    pool_load AS (
        SELECT
            pm.technician_id,
            pm.capacity_pool_id,
            COUNT(b.id) FILTER (WHERE b.technician_id = pm.technician_id) AS assigned_load,
            COUNT(b.id) FILTER (WHERE b.technician_id IS NULL) AS unassigned_load
        FROM pool_mapping pm
        LEFT JOIN public.bookings b 
               ON b.service_id      = p_sub_service_id
              AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE = p_date
              AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
        GROUP BY pm.technician_id, pm.capacity_pool_id
    )
    SELECT
        tp.user_id,
        pr.first_name,
        pr.last_name,
        pr.avatar_url,
        tp.rating,
        COALESCE(pl.assigned_load, 0)::BIGINT,
        pm.max_daily_capacity
    FROM pool_mapping pm
    JOIN public.technician_profiles tp ON tp.user_id = pm.technician_id
    JOIN public.profiles pr ON pr.id = tp.user_id
    JOIN pool_load pl ON pl.technician_id = pm.technician_id
                     AND pl.capacity_pool_id = pm.capacity_pool_id
    WHERE tp.is_available = true
      AND pr.account_status = 'active'
      AND COALESCE(pl.assigned_load, 0) < pm.max_daily_capacity
    ORDER BY 
        -- 1. Prioritize Group A (load_ratio < 0.5) over Group B (load_ratio >= 0.5)
        CASE WHEN (COALESCE(pl.assigned_load, 0)::float / pm.max_daily_capacity) < 0.5 THEN 1 ELSE 0 END DESC,
        -- 2. Sorting within groups: Group A sorts by capacity DESC first, Group B neutral
        CASE 
            WHEN (COALESCE(pl.assigned_load, 0)::float / pm.max_daily_capacity) < 0.5 
                THEN pm.max_daily_capacity 
            ELSE 0 
        END DESC,
        -- 3. Sort by lowest load_ratio (utilization) ascending
        (COALESCE(pl.assigned_load, 0)::float / pm.max_daily_capacity) ASC,
        -- 4. Tie-breaker: higher max capacity first
        pm.max_daily_capacity DESC,
        -- 5. Final tie-breaker: rating descending
        tp.rating DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. get_available_days
CREATE OR REPLACE FUNCTION public.get_available_days(
    p_sub_service_id UUID,
    p_start_date     DATE,
    p_end_date       DATE
) RETURNS TABLE (
    available_date DATE,
    is_available   BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.day::DATE,
        EXISTS (
            SELECT 1
            FROM public.get_available_technicians(p_sub_service_id, d.day::DATE)
            LIMIT 1
        ) AS is_available
    FROM generate_series(p_start_date, p_end_date, '1 day'::INTERVAL) AS d(day);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3. create_atomic_booking (V5.0)
CREATE OR REPLACE FUNCTION public.create_atomic_booking(
    p_user_id          UUID,
    p_sub_service_id   UUID,
    p_technician_id    UUID,
    p_scheduled_day    DATE,
    p_address_snapshot JSONB,
    p_service_snapshot JSONB,
    p_price_snapshot   JSONB,
    p_contact_name     TEXT DEFAULT 'Client',
    p_contact_phones   TEXT[] DEFAULT '{}'::TEXT[],
    p_start_time_slot  TIME DEFAULT '09:00'
) RETURNS UUID AS $$
DECLARE
    v_tech_id      UUID;
    v_booking_id   UUID;
    v_readable_id  TEXT;
    v_lock_key_1   INT;
    v_lock_key_2   INT;
BEGIN
    -- أ. التعيين التلقائي إذا لم يحدد المدير فنياً
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

    -- ب. حماية من تضارب المواعيد (Advisory Lock)
    v_lock_key_1 := hashtext(v_tech_id::TEXT);
    v_lock_key_2 := hashtext(p_scheduled_day::TEXT);
    PERFORM pg_advisory_xact_lock(v_lock_key_1, v_lock_key_2);

    -- ج. الإدخال في قاعدة البيانات (الحالة فوراً assigned)
    INSERT INTO public.bookings (
        user_id, technician_id, service_id, scheduled_day, start_time_slot,
        address_snapshot, service_snapshot, price_snapshot, 
        contact_name, contact_phones, status, assigned_at
    ) VALUES (
        p_user_id, v_tech_id, p_sub_service_id, p_scheduled_day, p_start_time_slot,
        p_address_snapshot, p_service_snapshot, p_price_snapshot, 
        p_contact_name, p_contact_phones, 'assigned', NOW()
    ) RETURNING id, readable_id INTO v_booking_id, v_readable_id;

    -- تم الاعتماد بالكامل على نظام الإشعارات الآلي (Trigger) لمنع التكرار

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

-- 4. نظام القبول التلقائي بعد ساعتين (Auto-Accept Logic)
CREATE OR REPLACE FUNCTION public.process_auto_accept_bookings()
RETURNS VOID AS $$
DECLARE
    v_record RECORD;
BEGIN
    FOR v_record IN (
        SELECT id, user_id, technician_id, readable_id, status
        FROM public.bookings
        WHERE status = 'assigned' 
          AND assigned_at < (NOW() - INTERVAL '2 hours')
    ) LOOP
        -- نستخدم دالة التحويل الرسمية لضمان تسجيل الأحداث والوقت
        PERFORM public.transition_booking(
            v_record.id, 
            'accepted'::order_status, 
            v_record.technician_id, 
            'technician',
            NULL, 
            'تم القبول التلقائي بواسطة النظام بعد مرور ساعتين من التعيين.'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
