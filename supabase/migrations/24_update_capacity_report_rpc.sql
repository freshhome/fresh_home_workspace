-- Update get_technician_capacity_report to include main_service_id
DROP FUNCTION IF EXISTS public.get_technician_capacity_report(DATE);

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
