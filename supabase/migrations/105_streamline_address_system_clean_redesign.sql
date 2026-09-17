-- ==============================================================================
-- Migration: 105_streamline_address_system_clean_redesign.sql
-- Description: Production-grade Clean Redesign of Fresh Home Address System
--              - Adds address_details and location_url
--              - Removes fragmented fields (street, building, floor, apartment, landmark, property_type, postal_code, address_label)
--              - Updates check constraints, triggers, and sync_user_profile RPC
-- Spec Reference: implementation_plan.md
-- ==============================================================================

BEGIN;

-- 1. ADD NEW CLEAN ADDRESS COLUMNS
ALTER TABLE public.user_addresses 
    ADD COLUMN IF NOT EXISTS address_details TEXT,
    ADD COLUMN IF NOT EXISTS location_url TEXT;

-- 2. MIGRATE ANY EXISTING ROWS TO POPULATE address_details IF PRESENT
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_addresses' AND column_name = 'street_or_compound'
    ) THEN
        UPDATE public.user_addresses
        SET address_details = TRIM(
            CONCAT_WS(', ', 
                NULLIF(street_or_compound, ''),
                NULLIF(building_identifier, ''),
                CASE WHEN floor IS NOT NULL AND floor != '' THEN 'الدور ' || floor ELSE NULL END,
                CASE WHEN apartment_or_unit IS NOT NULL AND apartment_or_unit != '' THEN 'شقة ' || apartment_or_unit ELSE NULL END,
                NULLIF(landmark, '')
            )
        )
        WHERE address_details IS NULL OR address_details = '';
    END IF;
END $$;

-- For any remaining rows where address_details might still be empty
UPDATE public.user_addresses 
SET address_details = 'تفاصيل العنوان غير محددة' 
WHERE address_details IS NULL OR address_details = '';

-- Set NOT NULL on address_details
ALTER TABLE public.user_addresses 
    ALTER COLUMN address_details SET NOT NULL;

-- 3. DROP LEGACY CHECK CONSTRAINTS
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_street_or_compound_length;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_building_identifier_length;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_property_type_enum;

-- 4. DROP LEGACY COLUMNS (CLEAN REDESIGN)
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS street_or_compound CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS building_identifier CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS floor CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS apartment_or_unit CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS landmark CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS property_type CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS postal_code CASCADE;
ALTER TABLE public.user_addresses DROP COLUMN IF EXISTS address_label CASCADE;

-- 5. ADD CONSTRAINT FOR ADDRESS DETAILS LENGTH
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_address_details_length;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_address_details_length 
    CHECK (length(trim(address_details)) >= 5 AND length(address_details) <= 500);

-- 6. UPDATE PRIMARY ADDRESS SWITCH TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.fn_handle_primary_address_switch()
RETURNS TRIGGER AS $$
DECLARE
    active_address_count INTEGER;
BEGIN
    -- Automatically trim all text fields
    NEW.governorate := trim(NEW.governorate);
    NEW.city := trim(NEW.city);
    NEW.district := trim(NEW.district);
    NEW.address_details := trim(NEW.address_details);
    IF NEW.location_url IS NOT NULL THEN NEW.location_url := trim(NEW.location_url); END IF;

    -- Count active non-deleted addresses for this user
    SELECT COUNT(*) INTO active_address_count
    FROM public.user_addresses
    WHERE user_id = NEW.user_id
      AND deleted_at IS NULL
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

    -- If this is the user's first active address, automatically make it primary
    IF active_address_count = 0 AND NEW.deleted_at IS NULL THEN
        NEW.is_primary := true;
    END IF;

    -- If setting is_primary = true, unset is_primary for all other active addresses of this user
    IF NEW.is_primary = true AND NEW.deleted_at IS NULL THEN
        UPDATE public.user_addresses
        SET is_primary = false, updated_at = NOW()
        WHERE user_id = NEW.user_id
          AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
          AND is_primary = true
          AND deleted_at IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS trg_handle_primary_address_switch ON public.user_addresses;
CREATE TRIGGER trg_handle_primary_address_switch
BEFORE INSERT OR UPDATE ON public.user_addresses
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_primary_address_switch();

-- 7. UPDATE SYNC_USER_PROFILE RPC (CLEAN REDESIGNED SCHEMA)
CREATE OR REPLACE FUNCTION public.sync_user_profile(
    p_user_id UUID, 
    p_phones JSONB, 
    p_addresses JSONB
) RETURNS VOID AS $$
DECLARE 
    phone_record JSONB; 
    address_record JSONB;
BEGIN
    IF auth.uid() != p_user_id AND NOT public.is_admin() THEN 
        RAISE EXCEPTION 'Unauthorized'; 
    END IF;

    -- Synchronize Phones
    DELETE FROM public.user_phones 
    WHERE user_id = p_user_id 
      AND id NOT IN (SELECT (val->>'id')::UUID FROM jsonb_array_elements(p_phones) AS val WHERE val->>'id' IS NOT NULL);

    FOR phone_record IN SELECT * FROM jsonb_array_elements(p_phones) LOOP
        INSERT INTO public.user_phones (id, user_id, phone_number, is_primary, is_verified)
        VALUES (
            COALESCE((phone_record->>'id')::UUID, gen_random_uuid()), 
            p_user_id, 
            phone_record->>'phone_number', 
            COALESCE((phone_record->>'is_primary')::BOOLEAN, false), 
            COALESCE((phone_record->>'is_verified')::BOOLEAN, false)
        )
        ON CONFLICT (id) DO UPDATE SET 
            phone_number = EXCLUDED.phone_number, 
            is_primary = EXCLUDED.is_primary, 
            is_verified = EXCLUDED.is_verified, 
            updated_at = NOW();
    END LOOP;

    -- Synchronize Addresses (Clean Redesigned Address System)
    DELETE FROM public.user_addresses 
    WHERE user_id = p_user_id 
      AND id NOT IN (SELECT (val->>'id')::UUID FROM jsonb_array_elements(p_addresses) AS val WHERE val->>'id' IS NOT NULL);

    FOR address_record IN SELECT * FROM jsonb_array_elements(p_addresses) LOOP
        INSERT INTO public.user_addresses (
            id, 
            user_id, 
            governorate, 
            city, 
            district, 
            address_details, 
            location_url, 
            latitude, 
            longitude, 
            governorate_id,
            city_id,
            district_id,
            is_primary
        )
        VALUES (
            COALESCE((address_record->>'id')::UUID, gen_random_uuid()),
            p_user_id,
            COALESCE(address_record->>'governorate', ''),
            COALESCE(address_record->>'city', ''),
            COALESCE(address_record->>'district', ''),
            COALESCE(address_record->>'address_details', address_record->>'details', ''),
            address_record->>'location_url',
            (address_record->>'latitude')::DOUBLE PRECISION,
            (address_record->>'longitude')::DOUBLE PRECISION,
            (address_record->>'governorate_id')::INT,
            (address_record->>'city_id')::INT,
            (address_record->>'district_id')::INT,
            COALESCE((address_record->>'is_primary')::BOOLEAN, false)
        )
        ON CONFLICT (id) DO UPDATE SET 
            governorate = EXCLUDED.governorate,
            city = EXCLUDED.city,
            district = EXCLUDED.district,
            address_details = EXCLUDED.address_details,
            location_url = EXCLUDED.location_url,
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            governorate_id = EXCLUDED.governorate_id,
            city_id = EXCLUDED.city_id,
            district_id = EXCLUDED.district_id,
            is_primary = EXCLUDED.is_primary,
            updated_at = NOW();
    END LOOP;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. FORMAL CONTRACT DOCUMENTATION FOR ADDRESS SNAPSHOT V3
COMMENT ON COLUMN public.bookings.address_snapshot IS 
'Versioned immutable address snapshot (Snapshot V3: supports administrative hierarchy governorate/city/district, unified address_details, and optional location coordinates/url).';

COMMIT;
