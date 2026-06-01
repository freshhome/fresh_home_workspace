-- ==============================================================================
-- Fresh Home: Capacity Override System (Phase 1)
-- Description: Dynamic layer for technician capacity and day-off management.
-- Applies AFTER: 04_assignment_system.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.capacity_overrides (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id         UUID NOT NULL,
    technician_id   UUID NOT NULL,
    override_date   DATE NOT NULL,
    new_capacity    INTEGER,
    is_blocked      BOOLEAN DEFAULT FALSE,
    reason          TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints: Validation
    CONSTRAINT check_positive_capacity CHECK (new_capacity >= 0),
    
    -- Constraint: Mutual Exclusivity (Approved Fix)
    -- Ensures a row is either a day-off OR a capacity change, but never both or neither.
    CONSTRAINT check_override_state CHECK (
        (is_blocked = TRUE AND new_capacity IS NULL)
        OR
        (is_blocked = FALSE AND new_capacity IS NOT NULL)
    ),

    -- Constraint: Uniqueness
    -- A technician can only have one override per pool per date.
    CONSTRAINT unique_tech_pool_date UNIQUE (technician_id, pool_id, override_date),

    -- Foreign Keys
    -- Standard FK to technician_profiles
    CONSTRAINT fk_override_technician
        FOREIGN KEY (technician_id)
        REFERENCES public.technician_profiles(user_id)
        ON DELETE CASCADE,

    -- Composite FK enforces Ownership: pool must belong to the same technician.
    -- This references the unique constraint (technician_id, id) in capacity_pools.
    CONSTRAINT fk_override_pool_ownership
        FOREIGN KEY (technician_id, pool_id)
        REFERENCES public.capacity_pools(technician_id, id)
        ON DELETE RESTRICT
);

-- Indexing for performance
CREATE INDEX IF NOT EXISTS idx_overrides_pool_date 
    ON public.capacity_overrides(pool_id, override_date);

CREATE INDEX IF NOT EXISTS idx_overrides_tech_date 
    ON public.capacity_overrides(technician_id, override_date);

-- Automation: Updated At Trigger
CREATE TRIGGER trg_capacity_overrides_updated_at
    BEFORE UPDATE ON public.capacity_overrides
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Documentation
COMMENT ON TABLE public.capacity_overrides IS 'Stores dynamic capacity changes and day-off blocks for technicians.';
COMMENT ON COLUMN public.capacity_overrides.pool_id IS 'The capacity pool being overridden.';
COMMENT ON COLUMN public.capacity_overrides.is_blocked IS 'If true, the technician is unavailable (Day-off) and capacity is effectively 0.';
COMMENT ON COLUMN public.capacity_overrides.new_capacity IS 'The specific capacity for this date if not blocked.';
