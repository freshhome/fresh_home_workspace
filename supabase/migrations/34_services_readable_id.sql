-- ==============================================================================
-- Fresh Home: Auto-Incrementing Readable IDs for Services Table
-- Migration ID: 34_services_readable_id
-- Description: Convert services table id and all foreign keys from UUID to TEXT
-- and set up auto-increment readable ID generator (e.g., FH-S-100151).
-- ==============================================================================

BEGIN;

-- 1. Create the sequence starting from 100151
CREATE SEQUENCE IF NOT EXISTS public.services_number_seq START 100151;

-- 2. Drop all foreign key constraints referencing services(id) to allow changing column types
ALTER TABLE public.services DROP CONSTRAINT IF EXISTS services_parent_id_fkey;
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_service_id_fkey;
ALTER TABLE public.technician_skills DROP CONSTRAINT IF EXISTS technician_skills_service_id_fkey;
ALTER TABLE public.pricing_rules DROP CONSTRAINT IF EXISTS pricing_rules_service_id_fkey;
ALTER TABLE public.pricing_discounts DROP CONSTRAINT IF EXISTS pricing_discounts_service_id_fkey;
ALTER TABLE public.pricing_versions DROP CONSTRAINT IF EXISTS pricing_versions_service_id_fkey;

-- Also check if there's any other constraint name like technician_skills_sub_service_id_fkey
ALTER TABLE public.technician_skills DROP CONSTRAINT IF EXISTS technician_skills_sub_service_id_fkey;

-- 3. Alter column types from UUID to TEXT
ALTER TABLE public.services ALTER COLUMN id TYPE TEXT USING id::TEXT;
ALTER TABLE public.services ALTER COLUMN parent_id TYPE TEXT USING parent_id::TEXT;
ALTER TABLE public.bookings ALTER COLUMN service_id TYPE TEXT USING service_id::TEXT;
ALTER TABLE public.technician_skills ALTER COLUMN sub_service_id TYPE TEXT USING sub_service_id::TEXT;
ALTER TABLE public.pricing_rules ALTER COLUMN sub_service_id TYPE TEXT USING sub_service_id::TEXT;
ALTER TABLE public.pricing_discounts ALTER COLUMN sub_service_id TYPE TEXT USING sub_service_id::TEXT;
ALTER TABLE public.pricing_versions ALTER COLUMN sub_service_id TYPE TEXT USING sub_service_id::TEXT;

-- 4. Recreate foreign key constraints referencing services(id) with TEXT types
ALTER TABLE public.services
    ADD CONSTRAINT services_parent_id_fkey 
    FOREIGN KEY (parent_id) 
    REFERENCES public.services(id)
    ON DELETE CASCADE;

ALTER TABLE public.bookings
    ADD CONSTRAINT bookings_service_id_fkey 
    FOREIGN KEY (service_id) 
    REFERENCES public.services(id)
    ON DELETE RESTRICT;

ALTER TABLE public.technician_skills
    ADD CONSTRAINT technician_skills_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON DELETE CASCADE;

ALTER TABLE public.pricing_rules
    ADD CONSTRAINT pricing_rules_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON DELETE CASCADE;

ALTER TABLE public.pricing_discounts
    ADD CONSTRAINT pricing_discounts_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON DELETE CASCADE;

ALTER TABLE public.pricing_versions
    ADD CONSTRAINT pricing_versions_service_id_fkey 
    FOREIGN KEY (sub_service_id) 
    REFERENCES public.services(id)
    ON DELETE CASCADE;

-- 5. Create or Replace function to generate auto-incrementing readable ID (e.g. FH-S-100151)
CREATE OR REPLACE FUNCTION public.fn_generate_service_id()
RETURNS TRIGGER AS $$
BEGIN
    -- If ID is null, empty, or a client-generated UUID, overwrite/generate a readable ID using sequence
    IF NEW.id IS NULL OR NEW.id = '' OR NEW.id ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
        NEW.id := 'FH-S-' || nextval('public.services_number_seq')::TEXT;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger BEFORE INSERT
DROP TRIGGER IF EXISTS trg_generate_service_id ON public.services;
CREATE TRIGGER trg_generate_service_id
BEFORE INSERT ON public.services
FOR EACH ROW EXECUTE FUNCTION public.fn_generate_service_id();

COMMIT;
