-- ==============================================================================
-- Fresh Home: Row Level Security (RLS) Policies for Unified Services Tree
-- Migration ID: 33_services_rls
-- ==============================================================================

BEGIN;

-- 1. Enable RLS on the services table
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies to prevent conflicts
DROP POLICY IF EXISTS "Anyone can read services" ON public.services;
DROP POLICY IF EXISTS "Admins can manage services" ON public.services;
DROP POLICY IF EXISTS "Admins can do everything on services" ON public.services;
DROP POLICY IF EXISTS "Public read access for services" ON public.services;

-- 3. Create public SELECT policy (Anyone can read services)
CREATE POLICY "Anyone can read services"
ON public.services
FOR SELECT
USING (true);

-- 4. Create admin ALL policy (Admins have full manage access)
CREATE POLICY "Admins can manage services"
ON public.services
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

COMMIT;
