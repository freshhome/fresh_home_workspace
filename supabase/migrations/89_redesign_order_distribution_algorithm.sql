-- Migration ID: 89_redesign_order_distribution_algorithm
-- Description: Redesign get_available_technicians to follow a capacity-aware, fair distribution model prioritizing higher-capacity technicians below 50% load_ratio.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_available_technicians(
    p_sub_service_id TEXT,
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
            COUNT(b.id) FILTER (WHERE b.technician_id = pm.technician_id) AS assigned_load
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

COMMIT;
