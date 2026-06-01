-- ==============================================================================
-- Fresh Home: Granular Capacity Management RPC
-- Description: Provides a detailed breakdown of technician cabinets (pools)
--              and their slots for a specific date.
-- ==============================================================================

-- Drop old function if exists
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
