-- ==============================================================================
-- Migration: 97_address_system_v2_schema.sql
-- Description: Production-grade schema implementation for Fresh Home Address System V2
-- Author: Principal Architect
-- Spec Reference: docs/address_system_v2_specification.md
-- ==============================================================================

-- 1. DROP OLD TABLE IF EXISTS (MIGRATION SAFEGUARD FOR V2 SCHEMAS)
-- Ensure clean creation of the normalized V2 schema while maintaining cascade compatibility
CREATE TABLE IF NOT EXISTS public.user_addresses_v2_backup AS 
SELECT * FROM public.user_addresses WHERE false;

-- 2. CREATE OR RESTRUCTURE USER_ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS public.user_addresses_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    governorate TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT NOT NULL,
    street_or_compound TEXT NOT NULL,
    building_identifier TEXT NOT NULL,
    floor TEXT,
    apartment_or_unit TEXT,
    landmark TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_primary BOOLEAN DEFAULT false,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- If original user_addresses exists, migrate schema or recreate cleanly
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_addresses' AND table_schema = 'public') THEN
        -- Alter existing table to ensure all V2 columns exist with exact naming
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'district') THEN
            ALTER TABLE public.user_addresses ADD COLUMN district TEXT NOT NULL DEFAULT 'District';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'street_or_compound') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'street') THEN
                ALTER TABLE public.user_addresses RENAME COLUMN street TO street_or_compound;
            ELSE
                ALTER TABLE public.user_addresses ADD COLUMN street_or_compound TEXT NOT NULL DEFAULT 'Street';
            END IF;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'building_identifier') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'building_number') THEN
                ALTER TABLE public.user_addresses RENAME COLUMN building_number TO building_identifier;
            ELSE
                ALTER TABLE public.user_addresses ADD COLUMN building_identifier TEXT NOT NULL DEFAULT 'Building';
            END IF;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'apartment_or_unit') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'apartment') THEN
                ALTER TABLE public.user_addresses RENAME COLUMN apartment TO apartment_or_unit;
            ELSE
                ALTER TABLE public.user_addresses ADD COLUMN apartment_or_unit TEXT;
            END IF;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'landmark') THEN
            ALTER TABLE public.user_addresses ADD COLUMN landmark TEXT;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'property_type') THEN
            ALTER TABLE public.user_addresses ADD COLUMN property_type TEXT DEFAULT 'residential';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_addresses' AND column_name = 'deleted_at') THEN
            ALTER TABLE public.user_addresses ADD COLUMN deleted_at TIMESTAMPTZ;
        END IF;

        DROP TABLE IF EXISTS public.user_addresses_v2 CASCADE;
    ELSE
        ALTER TABLE public.user_addresses_v2 RENAME TO user_addresses;
    END IF;
END $$;

-- 3. SANITATION & INTEGRITY CHECK CONSTRAINTS
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_governorate_length;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_governorate_length 
    CHECK (length(trim(governorate)) >= 2 AND length(governorate) <= 100);

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_city_length;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_city_length 
    CHECK (length(trim(city)) >= 2 AND length(city) <= 100);

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_district_length;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_district_length 
    CHECK (length(trim(district)) >= 2 AND length(district) <= 100);

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_street_or_compound_length;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_street_or_compound_length 
    CHECK (length(trim(street_or_compound)) >= 3 AND length(street_or_compound) <= 255);

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_building_identifier_length;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_building_identifier_length 
    CHECK (length(trim(building_identifier)) >= 1 AND length(building_identifier) <= 100);

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_latitude_range;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_latitude_range 
    CHECK (latitude IS NULL OR (latitude >= -90.0 AND latitude <= 90.0));

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_longitude_range;
ALTER TABLE public.user_addresses ADD CONSTRAINT chk_longitude_range 
    CHECK (longitude IS NULL OR (longitude >= -180.0 AND longitude <= 180.0));

-- 4. PARTIAL UNIQUE INDEX (MANDATORY ARCHITECTURAL CONSTRAINT)
-- Enforces: "There must never exist more than one active primary address for the same user"
DROP INDEX IF EXISTS public.idx_user_primary_address;
CREATE UNIQUE INDEX idx_user_primary_address
ON public.user_addresses(user_id)
WHERE is_primary = TRUE
AND deleted_at IS NULL;

-- 5. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id 
ON public.user_addresses(user_id) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_user_addresses_lookup 
ON public.user_addresses(governorate, city, district) 
WHERE deleted_at IS NULL;

-- 6. AUTOMATIC TIMESTAMPTZ & PRIMARY ADDRESS TRIGGERS
CREATE OR REPLACE FUNCTION public.fn_update_user_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_addresses_updated_at ON public.user_addresses;
CREATE TRIGGER trg_user_addresses_updated_at
BEFORE UPDATE ON public.user_addresses
FOR EACH ROW
EXECUTE FUNCTION public.fn_update_user_addresses_updated_at();

-- Trigger Function: Atomic Primary Address Switching & Automatic First Address Primary
CREATE OR REPLACE FUNCTION public.fn_handle_primary_address_switch()
RETURNS TRIGGER AS $$
DECLARE
    active_address_count INTEGER;
BEGIN
    -- Trim whitespace on text fields automatically
    NEW.governorate := trim(NEW.governorate);
    NEW.city := trim(NEW.city);
    NEW.district := trim(NEW.district);
    NEW.street_or_compound := trim(NEW.street_or_compound);
    NEW.building_identifier := trim(NEW.building_identifier);
    IF NEW.floor IS NOT NULL THEN NEW.floor := trim(NEW.floor); END IF;
    IF NEW.apartment_or_unit IS NOT NULL THEN NEW.apartment_or_unit := trim(NEW.apartment_or_unit); END IF;
    IF NEW.landmark IS NOT NULL THEN NEW.landmark := trim(NEW.landmark); END IF;

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

DROP TRIGGER IF EXISTS trg_handle_primary_address_switch ON public.user_addresses;
CREATE TRIGGER trg_handle_primary_address_switch
BEFORE INSERT OR UPDATE ON public.user_addresses
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_primary_address_switch();

-- 7. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own non-deleted addresses" ON public.user_addresses;
CREATE POLICY "Users can view their own non-deleted addresses"
ON public.user_addresses
FOR SELECT
USING (auth.uid() = user_id AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can insert their own addresses" ON public.user_addresses;
CREATE POLICY "Users can insert their own addresses"
ON public.user_addresses
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own addresses" ON public.user_addresses;
CREATE POLICY "Users can update their own addresses"
ON public.user_addresses
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own addresses" ON public.user_addresses;
CREATE POLICY "Users can delete their own addresses"
ON public.user_addresses
FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all addresses" ON public.user_addresses;
CREATE POLICY "Admins can view all addresses"
ON public.user_addresses
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur 
        JOIN public.roles r ON ur.role_id = r.id 
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

DROP POLICY IF EXISTS "Technicians can view addresses of assigned bookings" ON public.user_addresses;
CREATE POLICY "Technicians can view addresses of assigned bookings"
ON public.user_addresses
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.bookings b 
        WHERE b.technician_id = auth.uid() 
          AND b.address_id = public.user_addresses.id
    )
);

-- ============================================================================
-- 8. PROFILE SYNCHRONIZATION RPC UPDATE (Address System V2 Compatibility)
-- ============================================================================
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

    -- Synchronize Addresses (Address System V2 Columns)
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
            street_or_compound, 
            building_identifier, 
            floor, 
            apartment_or_unit, 
            property_type, 
            postal_code, 
            landmark, 
            address_label, 
            latitude, 
            longitude, 
            is_primary
        )
        VALUES (
            COALESCE((address_record->>'id')::UUID, gen_random_uuid()),
            p_user_id,
            COALESCE(address_record->>'governorate', ''),
            COALESCE(address_record->>'city', ''),
            COALESCE(address_record->>'district', 'District'),
            COALESCE(address_record->>'street_or_compound', address_record->>'street', ''),
            COALESCE(address_record->>'building_identifier', address_record->>'building_number', ''),
            address_record->>'floor',
            COALESCE(address_record->>'apartment_or_unit', address_record->>'apartment'),
            COALESCE(address_record->>'property_type', 'residential'),
            address_record->>'postal_code',
            address_record->>'landmark',
            address_record->>'address_label',
            (address_record->>'latitude')::DOUBLE PRECISION,
            (address_record->>'longitude')::DOUBLE PRECISION,
            COALESCE((address_record->>'is_primary')::BOOLEAN, false)
        )
        ON CONFLICT (id) DO UPDATE SET 
            governorate = EXCLUDED.governorate,
            city = EXCLUDED.city,
            district = EXCLUDED.district,
            street_or_compound = EXCLUDED.street_or_compound,
            building_identifier = EXCLUDED.building_identifier,
            floor = EXCLUDED.floor,
            apartment_or_unit = EXCLUDED.apartment_or_unit,
            property_type = EXCLUDED.property_type,
            postal_code = EXCLUDED.postal_code,
            landmark = EXCLUDED.landmark,
            address_label = EXCLUDED.address_label,
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            is_primary = EXCLUDED.is_primary,
            updated_at = NOW();
    END LOOP;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

