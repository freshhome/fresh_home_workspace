-- ==============================================================================
-- Fresh Home: Migration 70 - IAM Profiles Separation & Zero Round-Trip JWT Hook
-- Target: Restructures IAM profile subclasses & sets custom JWT claims hook
-- ==============================================================================

BEGIN;

-- 1. Create Class Table Inheritance (Profile Separation) subclass tables

-- Customer Profiles Table (Linked 1:1 to public.profiles)
CREATE TABLE IF NOT EXISTS public.customer_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    preferred_payment_method TEXT DEFAULT 'cash',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin Profiles Table (Linked 1:1 to public.profiles)
CREATE TABLE IF NOT EXISTS public.admin_profiles (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    admin_permissions TEXT[] DEFAULT '{}'::TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Setup Updated At triggers
DROP TRIGGER IF EXISTS trg_customer_profiles_updated_at ON public.customer_profiles;
CREATE TRIGGER trg_customer_profiles_updated_at 
    BEFORE UPDATE ON public.customer_profiles 
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_admin_profiles_updated_at ON public.admin_profiles;
CREATE TRIGGER trg_admin_profiles_updated_at 
    BEFORE UPDATE ON public.admin_profiles 
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- 3. Backfill existing profile subclasses based on current user roles
-- Backfill existing customers
INSERT INTO public.customer_profiles (user_id)
SELECT ur.user_id FROM public.user_roles ur
JOIN public.roles r ON ur.role_id = r.id
WHERE r.name = 'client'
ON CONFLICT (user_id) DO NOTHING;

-- Backfill existing admins
INSERT INTO public.admin_profiles (user_id, admin_permissions)
SELECT ur.user_id, ARRAY['all'] FROM public.user_roles ur
JOIN public.roles r ON ur.role_id = r.id
WHERE r.name = 'admin'
ON CONFLICT (user_id) DO NOTHING;

-- 4. Update assign_role_to_user to handle role-specific profiles
CREATE OR REPLACE FUNCTION public.assign_role_to_user(
    p_user_id UUID, 
    p_role_name TEXT, 
    p_service_ids UUID[] DEFAULT NULL
) RETURNS VOID AS $$
DECLARE 
    v_role_id INTEGER;
    v_service_id UUID;
BEGIN
    -- Authorization check
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    
    SELECT id INTO v_role_id FROM public.roles WHERE name = p_role_name;
    IF v_role_id IS NULL THEN RAISE EXCEPTION 'Role % not found', p_role_name; END IF;
    
    -- A. Insert the role mapping
    INSERT INTO public.user_roles (user_id, role_id) VALUES (p_user_id, v_role_id) ON CONFLICT DO NOTHING;
    
    -- B. Handle subclass profile instantiation
    IF p_role_name = 'client' THEN
        INSERT INTO public.customer_profiles (user_id) VALUES (p_user_id) ON CONFLICT (user_id) DO NOTHING;
    ELSIF p_role_name = 'technician' THEN
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
    ELSIF p_role_name = 'admin' THEN
        INSERT INTO public.admin_profiles (user_id, admin_permissions) VALUES (p_user_id, ARRAY['all']) ON CONFLICT (user_id) DO NOTHING;
    END IF;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Update handle_new_user trigger to instantiate customer profile on signup
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

    -- Insert basic profile
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

    -- Insert customer profile subclass record
    INSERT INTO public.customer_profiles (user_id, preferred_payment_method)
    VALUES (NEW.id, 'cash')
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Ensure exception inside profile creation doesn't crash the whole auth transaction
    -- but write a warning so it is logged
    RAISE WARNING 'handle_new_user failed: %', SQLERRM;
    RETURN NEW;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Implement Supabase Custom Access Token Hook
-- Description: Intercepts Supabase Auth token generation to inject the user's role and profile ID
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_roles JSONB;
    v_primary_role TEXT;
    claims JSONB;
BEGIN
    -- A. Resolve the User ID from the event context
    v_user_id := (event->>'user_id')::UUID;
    
    -- B. Fetch all assigned roles as a JSON array
    SELECT jsonb_agg(r.name) INTO v_roles
    FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = v_user_id;

    -- C. Fallback logic: default to client if no roles are explicitly mapped
    IF v_roles IS NULL THEN
        v_roles := '["client"]'::JSONB;
        v_primary_role := 'client';
    ELSE
        -- D. Determine the primary role for the user based on hierarchy (admin -> technician -> client)
        SELECT r.name INTO v_primary_role
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = v_user_id
        ORDER BY CASE r.name
            WHEN 'admin' THEN 1
            WHEN 'technician' THEN 2
            WHEN 'client' THEN 3
            ELSE 4
        END ASC
        LIMIT 1;
    END IF;

    -- E. Extract claims object
    claims := event->'claims';

    -- F. Initialize app_metadata if it is null
    IF jsonb_typeof(claims->'app_metadata') IS NULL OR jsonb_typeof(claims->'app_metadata') = 'null' THEN
        claims := jsonb_set(claims, '{app_metadata}', '{}'::JSONB);
    END IF;

    -- G. Inject customized claims for Zero Round-Trip login
    claims := jsonb_set(claims, '{app_metadata, roles}', v_roles);
    claims := jsonb_set(claims, '{app_metadata, user_role}', to_jsonb(v_primary_role));
    claims := jsonb_set(claims, '{app_metadata, profile_id}', to_jsonb(v_user_id));

    -- H. Re-embed the modified claims into the returned event object
    event := jsonb_set(event, '{claims}', claims);

    RETURN event;
END;
$$;

-- Apply grants and revoke public access for security hardening
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM public;

-- 7. Setup Row-Level Security (RLS) policies

-- Enable RLS
ALTER TABLE public.customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;

-- customer_profiles policies
DROP POLICY IF EXISTS "Users can view their own customer profile" ON public.customer_profiles;
CREATE POLICY "Users can view their own customer profile" ON public.customer_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own customer profile" ON public.customer_profiles;
CREATE POLICY "Users can update their own customer profile" ON public.customer_profiles
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can do everything on customer profiles" ON public.customer_profiles;
CREATE POLICY "Admins can do everything on customer profiles" ON public.customer_profiles
    FOR ALL USING (public.is_admin());

-- admin_profiles policies
DROP POLICY IF EXISTS "Admins can do everything on admin profiles" ON public.admin_profiles;
CREATE POLICY "Admins can do everything on admin profiles" ON public.admin_profiles
    FOR ALL USING (public.is_admin());

COMMIT;
