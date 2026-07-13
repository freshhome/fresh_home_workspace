-- Migration ID: 94_redesign_order_distribution_algorithm_v2
-- Description: Redesign get_available_technicians to use proportional share interleaving, rating priority, and FIFO/longest idle time.

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
            COUNT(b.id) FILTER (WHERE b.technician_id = pm.technician_id) AS assigned_load,
            COUNT(b.id) FILTER (WHERE b.technician_id IS NULL) AS unassigned_load,
            MAX(b.assigned_at) FILTER (WHERE b.technician_id = pm.technician_id) AS last_assigned_at
        FROM pool_mapping pm
        LEFT JOIN public.bookings b 
               ON (b.technician_id = pm.technician_id OR b.technician_id IS NULL)
              AND (b.scheduled_day AT TIME ZONE 'UTC')::DATE = p_date
              AND b.service_id IN (
                  SELECT ts_inner.sub_service_id
                  FROM public.technician_skills ts_inner
                  WHERE ts_inner.capacity_pool_id = pm.capacity_pool_id
              )
              AND b.status NOT IN ('cancelled'::public.order_status_v2, 'expired'::public.order_status_v2, 'failed_no_show'::public.order_status_v2)
        GROUP BY pm.technician_id, pm.capacity_pool_id
    ),
    candidates AS (
        SELECT
            tp.user_id,
            pr.first_name,
            pr.last_name,
            pr.avatar_url,
            tp.rating,
            (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::BIGINT as load,
            pm.max_daily_capacity,
            ((COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::float / pm.max_daily_capacity) as current_utilization,
            pl.last_assigned_at
        FROM pool_mapping pm
        JOIN public.technician_profiles tp ON tp.user_id = pm.technician_id
        JOIN public.profiles pr ON pr.id = tp.user_id
        JOIN pool_load pl ON pl.technician_id = pm.technician_id
                         AND pl.capacity_pool_id = pm.capacity_pool_id
        WHERE tp.is_available = true
          AND pr.account_status = 'active'
          AND (COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0)) < pm.max_daily_capacity
    ),
    utilization_check AS (
        SELECT EXISTS (
            SELECT 1 FROM candidates WHERE current_utilization < 0.5
        ) as has_anyone_under_fifty
    )
    SELECT
        c.user_id,
        c.first_name,
        c.last_name,
        c.avatar_url,
        c.rating,
        c.load,
        c.max_daily_capacity
    FROM candidates c
    CROSS JOIN utilization_check uc
    WHERE 
      -- Apply ExcludeExceedingFiftyPercentRule (منع تجاوز 50% قبل الجميع)
      (NOT uc.has_anyone_under_fifty OR c.current_utilization < 0.5)
    ORDER BY 
      -- Rule 1: Proportional Share Interleaving (prospective utilization ascending)
      ((c.load + 1)::float / c.max_daily_capacity) ASC,
      -- Tie-breaker: Larger capacity first
      c.max_daily_capacity DESC,
      -- Rule 2: Rating Ranking (higher rating first)
      c.rating DESC,
      -- Rule 3: FIFO / Longest Idle Time (last_assigned_at ascending)
      c.last_assigned_at ASC NULLS FIRST,
      -- Final Tie Breaker: Random
      random();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;
