-- ==============================================================================
-- Fresh Home: Migration to Unified Tree-Based Services Schema
-- Migration ID: 32_unified_services_tree
-- ==============================================================================

BEGIN;

-- 1. PRE-MIGRATION VALIDATION
DO $$
DECLARE
    v_orphans INT;
    v_missing_price INT;
BEGIN
    -- Verify there are no orphan sub_services referencing invalid main_service_id keys
    SELECT COUNT(*) INTO v_orphans
    FROM public.sub_services s
    LEFT JOIN public.main_services m ON s.main_service_id = m.id
    WHERE m.id IS NULL;
    
    IF v_orphans > 0 THEN
        RAISE EXCEPTION 'Migration aborted: Found % orphan sub_services referencing invalid main_service_id keys.', v_orphans;
    END IF;

    -- Verify all sub_services contain price_config (must be non-null to avoid constraint violation)
    SELECT COUNT(*) INTO v_missing_price
    FROM public.sub_services
    WHERE price_config IS NULL;
    
    IF v_missing_price > 0 THEN
        RAISE EXCEPTION 'Migration aborted: Found % sub_services missing price_config. All bookable services must have pricing configurations.', v_missing_price;
    END IF;
END $$;

-- 2. CREATE UNIFIED SERVICES TABLE
CREATE TABLE public.services (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id   UUID REFERENCES public.services(id) ON DELETE CASCADE,
    is_bookable BOOLEAN NOT NULL DEFAULT false,
    
    -- Multilingual content fields
    title       JSONB NOT NULL,
    description JSONB NOT NULL,
    instructions JSONB DEFAULT '{"ar": "", "en": ""}'::JSONB,
    
    -- Display & Status metadata
    image       TEXT,
    status      public.service_status DEFAULT 'active'::public.service_status,
    sort_order  INT DEFAULT 0,
    
    -- Bookable-only fields (Must be NULL if is_bookable = false)
    price_config JSONB,
    details      JSONB DEFAULT '[]'::JSONB,
    not_included JSONB DEFAULT '{}'::JSONB,
    
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for parent queries and search
CREATE INDEX idx_services_parent_id ON public.services(parent_id);
CREATE INDEX idx_services_is_bookable ON public.services(is_bookable);

-- 3. INTEGRITY CONSTRAINTS & VALIDATION RULES
-- Rule A: Bookable Nodes Constraint
ALTER TABLE public.services ADD CONSTRAINT chk_bookable_fields
CHECK (
    (is_bookable = true AND price_config IS NOT NULL) OR
    (is_bookable = false AND price_config IS NULL)
);

-- Rule B: Dynamic Pricing Schema Validation (Uses public.validate_price_config function)
ALTER TABLE public.services 
ADD CONSTRAINT chk_services_price_config 
CHECK (price_config IS NULL OR public.validate_price_config(price_config));

-- 4. PREVENT HIERARCHY & MUTABILITY VIOLATIONS (TRIGGERS)
CREATE OR REPLACE FUNCTION public.fn_check_service_tree_integrity()
RETURNS TRIGGER AS $$
BEGIN
    -- A. Prevent changing a service from bookable to non-bookable
    IF TG_OP = 'UPDATE' AND OLD.is_bookable = true AND NEW.is_bookable = false THEN
        RAISE EXCEPTION 'Cannot change a service from bookable to non-bookable once created.' 
            USING ERRCODE = 'P0008';
    END IF;

    -- B. On update, if service is marked as is_bookable = true, verify it has no child nodes
    IF TG_OP = 'UPDATE' AND NEW.is_bookable = true THEN
        IF EXISTS (SELECT 1 FROM public.services WHERE parent_id = NEW.id LIMIT 1) THEN
            RAISE EXCEPTION 'Cannot mark service as bookable because it has sub-categories.' 
                USING ERRCODE = 'P0005';
        END IF;
    END IF;

    -- C. Verify that the parent node (if assigned) is NOT bookable
    IF NEW.parent_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM public.services WHERE id = NEW.parent_id AND is_bookable = true LIMIT 1) THEN
            RAISE EXCEPTION 'Cannot assign a parent that is marked as bookable.' 
                USING ERRCODE = 'P0006';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_services_tree_integrity
BEFORE INSERT OR UPDATE ON public.services
FOR EACH ROW EXECUTE FUNCTION public.fn_check_service_tree_integrity();

-- 5. DATA MIGRATION COPY
-- A. Insert categories (main_services) as root-level non-bookable nodes
INSERT INTO public.services (
    id, parent_id, is_bookable, title, description, instructions, image, status, sort_order, created_at, updated_at
)
SELECT 
    id, 
    NULL::UUID AS parent_id, 
    false AS is_bookable, 
    title, 
    description, 
    '{"ar": "", "en": ""}'::jsonb AS instructions, 
    image, 
    status, 
    sort_order, 
    created_at, 
    updated_at
FROM public.main_services;

-- B. Insert services (sub_services) as bookable leaf nodes
INSERT INTO public.services (
    id, parent_id, is_bookable, title, description, instructions, image, status, sort_order, price_config, details, not_included, created_at, updated_at
)
SELECT 
    id, 
    main_service_id AS parent_id, 
    true AS is_bookable, 
    title, 
    description, 
    '{"ar": "", "en": ""}'::jsonb AS instructions, 
    image, 
    status, 
    sort_order, 
    price_config, 
    details, 
    '{}'::jsonb AS not_included, -- Default literal used since sub_services in production lacks this column
    created_at, 
    updated_at
FROM public.sub_services;

-- 6. RELATION & FOREIGN KEY UPDATES
-- A. public.bookings
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_service_id_fkey;
ALTER TABLE public.bookings
    ADD CONSTRAINT bookings_service_id_fkey 
    FOREIGN KEY (service_id) 
    REFERENCES public.services(id)
    ON DELETE RESTRICT;

-- B. public.technician_skills
ALTER TABLE public.technician_skills DROP CONSTRAINT IF EXISTS technician_skills_sub_service_id_fkey;
ALTER TABLE public.technician_skills
    ADD CONSTRAINT technician_skills_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON DELETE CASCADE;

-- Validation trigger ensuring technician skills map ONLY to bookable leaf nodes
CREATE OR REPLACE FUNCTION public.fn_verify_technician_skill_node()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.services WHERE id = NEW.sub_service_id AND is_bookable = true LIMIT 1) THEN
        RAISE EXCEPTION 'Technician skill must be linked to a bookable service node.' USING ERRCODE = 'P0007';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verify_technician_skill_node
BEFORE INSERT OR UPDATE ON public.technician_skills
FOR EACH ROW EXECUTE FUNCTION public.fn_verify_technician_skill_node();

-- C. public.technician_profiles
ALTER TABLE public.technician_profiles DROP COLUMN IF EXISTS main_service_id;

-- D. Pricing Tables Updates
ALTER TABLE public.pricing_rules DROP CONSTRAINT IF EXISTS pricing_rules_sub_service_id_fkey;
ALTER TABLE public.pricing_rules ADD CONSTRAINT pricing_rules_service_id_fkey FOREIGN KEY (sub_service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE public.pricing_discounts DROP CONSTRAINT IF EXISTS pricing_discounts_sub_service_id_fkey;
ALTER TABLE public.pricing_discounts ADD CONSTRAINT pricing_discounts_service_id_fkey FOREIGN KEY (sub_service_id) REFERENCES public.services(id) ON DELETE CASCADE;

ALTER TABLE public.pricing_versions DROP CONSTRAINT IF EXISTS pricing_versions_sub_service_id_fkey;
ALTER TABLE public.pricing_versions ADD CONSTRAINT pricing_versions_service_id_fkey FOREIGN KEY (sub_service_id) REFERENCES public.services(id) ON DELETE CASCADE;

-- 7. OFFLINE SYNC TRIGGER AUDIT & UNIFICATION
DROP TRIGGER IF EXISTS trg_main_services_sync ON public.main_services;
DROP TRIGGER IF EXISTS trg_sub_services_sync ON public.sub_services;

CREATE OR REPLACE FUNCTION public.update_sync_manifest() RETURNS TRIGGER AS $$
BEGIN
    -- Updates the unified services manifest under the single key 'services'
    UPDATE public.services_updated 
    SET services = services || jsonb_build_object(NEW.id::TEXT, NOW()),
        last_updated_at = NOW()
    WHERE id = true;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_services_sync 
AFTER INSERT OR UPDATE ON public.services 
FOR EACH ROW EXECUTE PROCEDURE public.update_sync_manifest();

-- 8. SAFE TABLE RENAMING (BACKUP STEP)
ALTER TABLE public.sub_services RENAME TO backup_sub_services;
ALTER TABLE public.main_services RENAME TO backup_main_services;
ALTER TABLE public.technician_services RENAME TO backup_technician_services;

COMMIT;
