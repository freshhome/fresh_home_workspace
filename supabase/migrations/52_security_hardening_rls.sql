-- ==============================================================================
-- Fresh Home: Security Hardening & Identity RLS Migration
-- Migration File: 52_security_hardening_rls.sql
-- Target Tables: profiles, user_roles, user_phones, user_addresses, technician_profiles
-- ==============================================================================

BEGIN;

-- 1. Enable RLS on Identity tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_phones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Define Policies for public.profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles" ON public.profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
    );

-- 3. Define Policies for public.user_roles
DROP POLICY IF EXISTS "Users can view their own roles" ON public.user_roles;
CREATE POLICY "Users can view their own roles" ON public.user_roles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view and manage all user roles" ON public.user_roles;
CREATE POLICY "Admins can view and manage all user roles" ON public.user_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
    );

-- 4. Define Policies for public.user_phones
DROP POLICY IF EXISTS "Users can manage their own phones" ON public.user_phones;
CREATE POLICY "Users can manage their own phones" ON public.user_phones
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all user phones" ON public.user_phones;
CREATE POLICY "Admins can view all user phones" ON public.user_phones
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
    );

-- 5. Define Policies for public.user_addresses
DROP POLICY IF EXISTS "Users can manage their own addresses" ON public.user_addresses;
CREATE POLICY "Users can manage their own addresses" ON public.user_addresses
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all user addresses" ON public.user_addresses;
CREATE POLICY "Admins can view all user addresses" ON public.user_addresses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
    );

-- 6. Define Policies for public.technician_profiles
DROP POLICY IF EXISTS "Anyone can select verified technicians" ON public.technician_profiles;
CREATE POLICY "Anyone can select verified technicians" ON public.technician_profiles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Technicians can update their own profile" ON public.technician_profiles;
CREATE POLICY "Technicians can update their own profile" ON public.technician_profiles
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins have full access on technician profiles" ON public.technician_profiles;
CREATE POLICY "Admins have full access on technician profiles" ON public.technician_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
    );

-- 7. Fix handle_new_user trigger function to parse Google Metadata
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger AS $$
DECLARE
    v_first_name TEXT;
    v_last_name  TEXT;
    v_full_name  TEXT;
BEGIN
    -- Extract full name or given name/family name from Google OAuth metadata
    v_first_name := COALESCE(
        NEW.raw_user_meta_data->>'first_name', 
        NEW.raw_user_meta_data->>'given_name'
    );
    v_last_name := COALESCE(
        NEW.raw_user_meta_data->>'last_name', 
        NEW.raw_user_meta_data->>'family_name'
    );
    v_full_name := NEW.raw_user_meta_data->>'full_name';

    -- Fallback: split full name if first name is null
    IF v_first_name IS NULL AND v_full_name IS NOT NULL THEN
        v_first_name := split_part(v_full_name, ' ', 1);
        v_last_name := substr(v_full_name, length(v_first_name) + 2);
    END IF;

    -- Final fallback to defaults
    v_first_name := COALESCE(v_first_name, 'User');
    v_last_name := COALESCE(v_last_name, '');

    -- Insert profile
    INSERT INTO public.profiles (id, first_name, last_name, email, avatar_url)
    VALUES (
        NEW.id, 
        v_first_name, 
        v_last_name, 
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture')
    );

    -- Assign default client role
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (NEW.id, (SELECT id FROM public.roles WHERE name = 'client'));

    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Ensure exception inside profile creation doesn't crash the whole auth transaction
    -- but write a warning so it is logged
    RAISE WARNING 'handle_new_user failed: %', SQLERRM;
    RETURN NEW;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Fix Deployment Drift: Attach the trigger to auth.users if not exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMIT;
