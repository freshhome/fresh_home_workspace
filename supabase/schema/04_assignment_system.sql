-- ==============================================================================
-- Fresh Home: Assignment System Schema (v3.0)
-- Description: Capacity Pool-based technician assignment architecture.
-- Applies AFTER: 01_core_schema.sql, 02_transactional_schema.sql, 03_professional_bookings.sql
-- ==============================================================================

-- ============================================================
-- STEP 1: Bind Technicians to one Main Service
-- ============================================================
ALTER TABLE public.technician_profiles
ADD COLUMN IF NOT EXISTS main_service_id UUID REFERENCES public.main_services(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.technician_profiles.main_service_id IS
    'Restricts this technician to a single main service category (Cleaning, Pest Control, Maintenance)';

CREATE INDEX IF NOT EXISTS idx_technician_main_service
    ON public.technician_profiles(main_service_id);


-- ============================================================
-- STEP 2: Capacity Pools
-- A named resource bucket owned by a specific technician.
-- Capacity is stored HERE — not on individual skill rows.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.capacity_pools (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id   UUID NOT NULL REFERENCES public.technician_profiles(user_id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    max_daily_capacity INTEGER NOT NULL DEFAULT 1 CHECK (max_daily_capacity > 0),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent two pools of identical meaning for the same technician
    UNIQUE (technician_id, title),

    -- Required for the composite FK in technician_skills (pool ownership enforcement)
    UNIQUE (technician_id, id)
);

CREATE INDEX IF NOT EXISTS idx_capacity_pools_technician
    ON public.capacity_pools(technician_id);

CREATE TRIGGER trg_capacity_pools_updated_at
    BEFORE UPDATE ON public.capacity_pools
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ============================================================
-- STEP 3: Technician Skills
-- Links a technician to a sub-service through a capacity pool.
-- Both a direct FK (for planner) and composite FK (for ownership).
-- ============================================================
CREATE TABLE IF NOT EXISTS public.technician_skills (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id    UUID NOT NULL REFERENCES public.technician_profiles(user_id) ON DELETE CASCADE,
    sub_service_id   UUID NOT NULL REFERENCES public.sub_services(id) ON DELETE CASCADE,
    capacity_pool_id UUID NOT NULL,
    is_active        BOOLEAN DEFAULT true,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW(),

    -- A technician cannot have the same sub-service skill twice
    UNIQUE (technician_id, sub_service_id),

    -- Direct FK for query planner optimization
    CONSTRAINT fk_skill_pool_direct
        FOREIGN KEY (capacity_pool_id)
        REFERENCES public.capacity_pools(id)
        ON DELETE CASCADE,

    -- Composite FK enforces ownership: pool must belong to the same technician
    CONSTRAINT fk_skill_pool_ownership
        FOREIGN KEY (technician_id, capacity_pool_id)
        REFERENCES public.capacity_pools(technician_id, id)
        ON DELETE CASCADE
);

-- Fast skill-to-technician lookup (hot path for get_available_technicians)
CREATE INDEX IF NOT EXISTS idx_skills_lookup
    ON public.technician_skills(sub_service_id, technician_id);

CREATE INDEX IF NOT EXISTS idx_technician_skills_pool
    ON public.technician_skills(capacity_pool_id);

CREATE TRIGGER trg_technician_skills_updated_at
    BEFORE UPDATE ON public.technician_skills
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ============================================================
-- STEP 4: Performance index for atomic capacity calculation
-- Used by create_atomic_booking load re-verification.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_booking_capacity
    ON public.bookings(technician_id, scheduled_day, service_id)
    WHERE status NOT IN (
        'cancelled_by_customer'::public.order_status, 
        'cancelled_by_admin'::public.order_status, 
        'cancelled_by_technician'::public.order_status
    );
