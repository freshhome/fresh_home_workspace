-- ==============================================================================
-- Fresh Home: Migrate Existing UUID Service IDs to Readable IDs (FH-S-100000+)
-- Migration ID: 37_migrate_old_uuids
-- Description: Re-create foreign keys with ON UPDATE CASCADE, migrate existing
-- UUIDs to FH-S-XXXXXX sequentially, and sync the sequence.
-- ==============================================================================

BEGIN;

-- 1. Drop existing foreign key constraints
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS services_parent_id_fkey;
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_service_id_fkey;
ALTER TABLE public.technician_skills DROP CONSTRAINT IF EXISTS technician_skills_service_id_fkey;
ALTER TABLE public.pricing_rules DROP CONSTRAINT IF EXISTS pricing_rules_service_id_fkey;
ALTER TABLE public.pricing_discounts DROP CONSTRAINT IF EXISTS pricing_discounts_service_id_fkey;
ALTER TABLE public.pricing_versions DROP CONSTRAINT IF EXISTS pricing_versions_service_id_fkey;
ALTER TABLE public.technician_skills DROP CONSTRAINT IF EXISTS technician_skills_sub_service_id_fkey;

-- 2. Re-create foreign key constraints with ON UPDATE CASCADE to enable ID changes to cascade automatically
ALTER TABLE public.services
    ADD CONSTRAINT services_parent_id_fkey 
    FOREIGN KEY (parent_id) 
    REFERENCES public.services(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE public.bookings
    ADD CONSTRAINT bookings_service_id_fkey 
    FOREIGN KEY (service_id) 
    REFERENCES public.services(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE public.technician_skills
    ADD CONSTRAINT technician_skills_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE public.pricing_rules
    ADD CONSTRAINT pricing_rules_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE public.pricing_discounts
    ADD CONSTRAINT pricing_discounts_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE public.pricing_versions
    ADD CONSTRAINT pricing_versions_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

-- 3. Run PL/pgSQL block to update all existing UUID IDs to FH-S-100000+ sequentially
DO $$
DECLARE
    r RECORD;
    v_seq INT := 100001;
BEGIN
    FOR r IN (
        SELECT id FROM public.services 
        WHERE id ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        ORDER BY is_bookable, sort_order, created_at
    ) LOOP
        UPDATE public.services 
        SET id = 'FH-S-' || v_seq::TEXT 
        WHERE id = r.id;
        
        v_seq := v_seq + 1;
    END LOOP;
    
    -- Sync sequence to restart from v_seq (e.g., if we updated up to 100012, next insert starts from 100013)
    EXECUTE 'ALTER SEQUENCE public.services_number_seq RESTART WITH ' || v_seq;
END $$;

COMMIT;
