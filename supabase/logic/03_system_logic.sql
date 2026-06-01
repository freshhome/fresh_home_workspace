-- ==============================================================================
-- Fresh Home: System Functions & Triggers (v2.2)
-- Description: Common Utility Functions and Automated State Management
-- ==============================================================================

-- 1. UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.handle_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

-- 2. PROFILE SYNCHRONIZATION (Used by Flutter App to auto-save addresses/phones)
CREATE OR REPLACE FUNCTION public.sync_user_profile(p_user_id UUID, p_phones JSONB, p_addresses JSONB) RETURNS VOID AS $$
DECLARE phone_record JSONB; address_record JSONB;
BEGIN
    IF auth.uid() != p_user_id AND NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    DELETE FROM public.user_phones WHERE user_id = p_user_id AND id NOT IN (SELECT (val->>'id')::UUID FROM jsonb_array_elements(p_phones) AS val WHERE val->>'id' IS NOT NULL);
    FOR phone_record IN SELECT * FROM jsonb_array_elements(p_phones) LOOP
        INSERT INTO public.user_phones (id, user_id, phone_number, is_primary, is_verified)
        VALUES (COALESCE((phone_record->>'id')::UUID, gen_random_uuid()), p_user_id, phone_record->>'phone_number', COALESCE((phone_record->>'is_primary')::BOOLEAN, false), COALESCE((phone_record->>'is_verified')::BOOLEAN, false))
        ON CONFLICT (id) DO UPDATE SET phone_number = EXCLUDED.phone_number, is_primary = EXCLUDED.is_primary, is_verified = EXCLUDED.is_verified, updated_at = NOW();
    END LOOP;
    DELETE FROM public.user_addresses WHERE user_id = p_user_id AND id NOT IN (SELECT (val->>'id')::UUID FROM jsonb_array_elements(p_addresses) AS val WHERE val->>'id' IS NOT NULL);
    FOR address_record IN SELECT * FROM jsonb_array_elements(p_addresses) LOOP
        INSERT INTO public.user_addresses (id, user_id, governorate, city, street, building_number, floor, apartment, latitude, longitude, is_primary)
        VALUES (COALESCE((address_record->>'id')::UUID, gen_random_uuid()), p_user_id, address_record->>'governorate', address_record->>'city', address_record->>'street', address_record->>'building_number', address_record->>'floor', address_record->>'apartment', (address_record->>'latitude')::DOUBLE PRECISION, (address_record->>'longitude')::DOUBLE PRECISION, COALESCE((address_record->>'is_primary')::BOOLEAN, false))
        ON CONFLICT (id) DO UPDATE SET governorate = EXCLUDED.governorate, city = EXCLUDED.city, street = EXCLUDED.street, building_number = EXCLUDED.building_number, floor = EXCLUDED.floor, apartment = EXCLUDED.apartment, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, is_primary = EXCLUDED.is_primary, updated_at = NOW();
    END LOOP;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. ROLE MANAGEMENT
-- Updated to support specialty assignment for technicians
DROP FUNCTION IF EXISTS public.assign_role_to_user(UUID, TEXT);
CREATE OR REPLACE FUNCTION public.assign_role_to_user(
    p_user_id UUID, 
    p_role_name TEXT, 
    p_service_ids UUID[] DEFAULT NULL
) RETURNS VOID AS $$
DECLARE 
    v_role_id INTEGER;
    v_service_id UUID;
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    
    SELECT id INTO v_role_id FROM public.roles WHERE name = p_role_name;
    IF v_role_id IS NULL THEN RAISE EXCEPTION 'Role % not found', p_role_name; END IF;
    
    -- 1. Insert the role
    INSERT INTO public.user_roles (user_id, role_id) VALUES (p_user_id, v_role_id) ON CONFLICT DO NOTHING;
    
    -- 2. Special handling for technicians
    IF p_role_name = 'technician' THEN
        -- Create technician profile if it doesn't exist
        INSERT INTO public.technician_profiles (user_id) VALUES (p_user_id) ON CONFLICT (user_id) DO NOTHING;
        
        -- Link to specific services if provided
        IF p_service_ids IS NOT NULL THEN
            FOREACH v_service_id IN ARRAY p_service_ids LOOP
                INSERT INTO public.technician_services (technician_id, sub_service_id, capacity_per_day, is_active)
                VALUES (p_user_id, v_service_id, 5, true)
                ON CONFLICT (technician_id, sub_service_id) DO NOTHING;
            END LOOP;
        END IF;
    END IF;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.user_roles ur JOIN public.roles r ON ur.role_id = r.id 
    WHERE ur.user_id = auth.uid() AND r.name = 'admin');
END; $$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 4. NEW USER REGISTRATION HANDLER
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, first_name, last_name, email, avatar_url)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'), 
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''), 
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    );
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (NEW.id, (SELECT id FROM public.roles WHERE name = 'client'));
    RETURN NEW;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. TRIGGER ASSIGNMENTS
-- profiles
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- technician_profiles
DROP TRIGGER IF EXISTS trg_technician_profiles_updated_at ON public.technician_profiles;
CREATE TRIGGER trg_technician_profiles_updated_at BEFORE UPDATE ON public.technician_profiles FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- technician_services
DROP TRIGGER IF EXISTS trg_technician_services_updated_at ON public.technician_services;
CREATE TRIGGER trg_technician_services_updated_at BEFORE UPDATE ON public.technician_services FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- bookings
DROP TRIGGER IF EXISTS trg_bookings_updated_at ON public.bookings;
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
