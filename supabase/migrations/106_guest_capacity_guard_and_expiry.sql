-- ==============================================================================
-- Migration: 106_guest_capacity_guard_and_expiry.sql
-- Description: Phase 1 (Step 1.1) - Guest Booking Capacity Guard & Expiry
--              1. Update get_available_technicians to exclude unconfirmed bookings
--                 (is_whatsapp_confirmed = false) from both assigned and unassigned loads.
--              2. Seed state transitions for 'created' status to allow system expiry
--                 and confirmation transitions.
--              3. Update check_whatsapp_confirmation_expiry to check both 'created'
--                 and 'assigned' unconfirmed bookings.
-- Spec Reference: docs_guest/guest_booking_rules.md & guest_booking_development_plan.md
-- ==============================================================================

BEGIN;

-- 1. SEED TRANSITION ENGINE TO ALLOW TRANSITIONS FROM 'created' STATUS
INSERT INTO public.state_transitions (from_status, to_status, allowed_role, is_active, condition_code)
VALUES 
    -- Cancellation by system or admin when expiry occurs or admin cancels
    ('created'::public.order_status_v2, 'cancelled'::public.order_status_v2, 'system', true, NULL),
    ('created'::public.order_status_v2, 'cancelled'::public.order_status_v2, 'admin', true, NULL),
    -- Assignment upon confirmation by customer (link), admin (manual), or system
    ('created'::public.order_status_v2, 'assigned'::public.order_status_v2, 'customer', true, NULL),
    ('created'::public.order_status_v2, 'assigned'::public.order_status_v2, 'admin', true, NULL),
    ('created'::public.order_status_v2, 'assigned'::public.order_status_v2, 'system', true, NULL)
ON CONFLICT (from_status, to_status, allowed_role) DO UPDATE
SET is_active = EXCLUDED.is_active,
    condition_code = EXCLUDED.condition_code;


-- 2. REDEFINE public.get_available_technicians WITH WHATSAPP CONFIRMATION CAPACITY GUARD
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
            COALESCE(
                CASE WHEN co.is_blocked THEN 0 ELSE co.new_capacity END,
                cp.max_daily_capacity
            )::INTEGER AS max_daily_capacity
        FROM public.technician_skills ts
        JOIN public.capacity_pools cp ON ts.capacity_pool_id = cp.id
        LEFT JOIN LATERAL (
            SELECT co_inner.is_blocked, co_inner.new_capacity
            FROM public.capacity_overrides co_inner
            WHERE co_inner.pool_id       = ts.capacity_pool_id
              AND co_inner.technician_id = ts.technician_id
              AND co_inner.override_date = p_date
            ORDER BY co_inner.override_date DESC, co_inner.created_at DESC
            LIMIT 1
        ) co ON TRUE
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
              -- Capacity Guard: Exclude unconfirmed WhatsApp bookings from consuming technician daily load
              AND (b.is_whatsapp_confirmed = true)
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
            CASE 
                WHEN pm.max_daily_capacity = 0 THEN 1.0 
                ELSE ((COALESCE(pl.assigned_load, 0) + COALESCE(pl.unassigned_load, 0))::float / pm.max_daily_capacity)
            END as current_utilization,
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
      -- Apply ExcludeExceedingFiftyPercentRule
      (NOT uc.has_anyone_under_fifty OR c.current_utilization < 0.5)
    ORDER BY 
      -- Rule 1: Proportional Share Interleaving (prospective utilization ascending)
      ((c.load + 1)::float / NULLIF(c.max_daily_capacity, 0)) ASC,
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


-- 3. UPDATE check_whatsapp_confirmation_expiry TO SUPPORT BOTH 'created' AND 'assigned'
CREATE OR REPLACE FUNCTION public.check_whatsapp_confirmation_expiry()
RETURNS VOID AS $$
DECLARE
    v_rec RECORD;
BEGIN
    FOR v_rec IN 
        SELECT id FROM public.bookings
        WHERE is_whatsapp_confirmed = false 
          AND status IN ('created'::public.order_status_v2, 'assigned'::public.order_status_v2)
          AND whatsapp_confirmation_expires_at < NOW()
    LOOP
        BEGIN
            -- Set trusted internal call flag to allow system state transition
            PERFORM set_config('app.trusted_internal_call', 'true', true);

            -- Call the official state machine to transition to cancelled
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

COMMIT;
