-- ═══════════════════════════════════════════════════════════════════════
-- Migration: 96_technician_smart_schedule_rpc.sql
-- Description: High-performance single-query batch RPC to retrieve a
--              technician's smart schedule across a date range (e.g. monthly).
--              Friday is a normal working day (technician sets days off manually).
--              Manually blocked day = Technician Day-Off / Holiday (إجازة).
-- ═══════════════════════════════════════════════════════════════════════

-- 1. DROP previous overloads
DROP FUNCTION IF EXISTS public.get_technician_smart_schedule(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.get_technician_smart_schedule(UUID, INTEGER) CASCADE;

-- 2. CREATE Range-Based get_technician_smart_schedule RPC
CREATE OR REPLACE FUNCTION public.get_technician_smart_schedule(
    p_technician_id UUID,
    p_start_date    DATE,
    p_end_date      DATE
)
RETURNS TABLE (
    "date"                  DATE,
    target_date             DATE,
    capacity                INTEGER,
    effective_capacity      INTEGER,
    bookings_count          INTEGER,
    current_load            INTEGER,
    utilization             NUMERIC,
    utilization_percentage  NUMERIC,
    status                  TEXT,
    suggested_status        TEXT,
    is_override             BOOLEAN,
    risk_score              NUMERIC,
    force_multiplier        NUMERIC,
    suggestion              TEXT
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Security & Access control: Technician themselves or Admin
    IF auth.uid() IS NOT NULL AND NOT (public.is_admin() OR auth.uid() = p_technician_id) THEN
        RAISE EXCEPTION 'Unauthorized: Access to this technician schedule is restricted.' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(p_start_date, p_end_date, INTERVAL '1 day')::DATE AS day
    ),
    tech_pool_days AS (
        SELECT
            d.day,
            cp.id AS pool_id,
            cp.max_daily_capacity,
            COALESCE(co.is_blocked, false) AS is_pool_blocked,
            co.new_capacity AS override_capacity,
            (co.pool_id IS NOT NULL) AS is_override,
            CASE
                WHEN COALESCE(co.is_blocked, false) THEN 0
                WHEN co.new_capacity IS NOT NULL THEN co.new_capacity
                ELSE cp.max_daily_capacity
            END AS effective_cap,
            (
                SELECT COUNT(*)::INTEGER
                FROM public.bookings b
                JOIN public.technician_skills ts ON ts.sub_service_id = b.service_id
                WHERE ts.capacity_pool_id = cp.id
                  AND b.scheduled_day = d.day
                  AND (b.technician_id = p_technician_id OR b.technician_id IS NULL)
                  AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
            ) AS pool_bookings
        FROM date_series d
        CROSS JOIN public.capacity_pools cp
        LEFT JOIN LATERAL (
            SELECT co_inner.pool_id, co_inner.is_blocked, co_inner.new_capacity, co_inner.slot_mask
            FROM public.capacity_overrides co_inner
            WHERE (co_inner.pool_id = cp.id OR co_inner.pool_id IS NULL)
              AND co_inner.technician_id = p_technician_id
              AND co_inner.override_date = d.day
            ORDER BY co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
        WHERE cp.technician_id = p_technician_id
    ),
    daily_summary AS (
        SELECT
            tpd.day,
            SUM(tpd.effective_cap)::INTEGER AS total_capacity,
            SUM(tpd.pool_bookings)::INTEGER AS total_bookings,
            BOOL_OR(tpd.is_override) AS has_override,
            BOOL_AND(tpd.is_pool_blocked) AS all_pools_blocked,
            BOOL_OR(tpd.is_pool_blocked) AS any_pool_blocked
        FROM tech_pool_days tpd
        GROUP BY tpd.day
    )
    SELECT
        d.day AS "date",
        d.day AS target_date,
        COALESCE(ds.total_capacity, 0)::INTEGER AS capacity,
        COALESCE(ds.total_capacity, 0)::INTEGER AS effective_capacity,
        COALESCE(ds.total_bookings, 0)::INTEGER AS bookings_count,
        COALESCE(ds.total_bookings, 0)::INTEGER AS current_load,
        CASE
            WHEN COALESCE(ds.total_capacity, 0) = 0 THEN 0.0
            ELSE ROUND((COALESCE(ds.total_bookings, 0)::NUMERIC / ds.total_capacity::NUMERIC), 2)
        END AS utilization,
        CASE
            WHEN COALESCE(ds.total_capacity, 0) = 0 THEN 0.0
            ELSE ROUND((COALESCE(ds.total_bookings, 0)::NUMERIC / ds.total_capacity::NUMERIC) * 100, 1)
        END AS utilization_percentage,
        CASE
            WHEN d.day < CURRENT_DATE THEN 'past'
            WHEN COALESCE(ds.all_pools_blocked, false) OR COALESCE(ds.total_capacity, 0) = 0 THEN 'holiday'
            WHEN COALESCE(ds.total_bookings, 0) >= COALESCE(ds.total_capacity, 0) AND COALESCE(ds.total_capacity, 0) > 0 THEN 'full'
            WHEN COALESCE(ds.total_bookings, 0) > 0 THEN 'partial'
            ELSE 'available'
        END AS status,
        CASE
            WHEN d.day < CURRENT_DATE THEN 'past'
            WHEN COALESCE(ds.all_pools_blocked, false) OR COALESCE(ds.total_capacity, 0) = 0 THEN 'holiday'
            WHEN COALESCE(ds.total_bookings, 0) >= COALESCE(ds.total_capacity, 0) AND COALESCE(ds.total_capacity, 0) > 0 THEN 'full'
            WHEN COALESCE(ds.total_bookings, 0) > 0 THEN 'partial'
            ELSE 'available'
        END AS suggested_status,
        COALESCE(ds.has_override, false) AS is_override,
        0.0::NUMERIC AS risk_score,
        1.0::NUMERIC AS force_multiplier,
        ''::TEXT AS suggestion
    FROM date_series d
    LEFT JOIN daily_summary ds ON ds.day = d.day
    ORDER BY d.day;
END;
$$;

-- 3. CREATE Overload for days_ahead backward compatibility
CREATE OR REPLACE FUNCTION public.get_technician_smart_schedule(
    p_technician_id UUID,
    p_days_ahead    INTEGER DEFAULT 30
)
RETURNS TABLE (
    "date"                  DATE,
    target_date             DATE,
    capacity                INTEGER,
    effective_capacity      INTEGER,
    bookings_count          INTEGER,
    current_load            INTEGER,
    utilization             NUMERIC,
    utilization_percentage  NUMERIC,
    status                  TEXT,
    suggested_status        TEXT,
    is_override             BOOLEAN,
    risk_score              NUMERIC,
    force_multiplier        NUMERIC,
    suggestion              TEXT
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT * 
    FROM public.get_technician_smart_schedule(
        p_technician_id,
        CURRENT_DATE,
        (CURRENT_DATE + (p_days_ahead - 1)::INTEGER)
    );
END;
$$;

-- 4. Grant permissions
GRANT EXECUTE ON FUNCTION public.get_technician_smart_schedule(UUID, DATE, DATE) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_technician_smart_schedule(UUID, INTEGER) TO authenticated, service_role;
