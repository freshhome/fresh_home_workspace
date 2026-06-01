-- Enable RLS on the new tables
ALTER TABLE public.capacity_pools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_skills ENABLE ROW LEVEL SECURITY;

-- 1. CAPACITY POOLS POLICIES
-- Admin has full access
CREATE POLICY "Admins can do everything on capacity_pools"
ON public.capacity_pools
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- Technicians can read their own pools
CREATE POLICY "Technicians can read own capacity_pools"
ON public.capacity_pools
FOR SELECT
USING (auth.uid() = technician_id);


-- 2. TECHNICIAN SKILLS POLICIES
-- Admin has full access
CREATE POLICY "Admins can do everything on technician_skills"
ON public.technician_skills
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- Technicians can read their own skills
CREATE POLICY "Technicians can read own technician_skills"
ON public.technician_skills
FOR SELECT
USING (auth.uid() = technician_id);

-- Also ensure technician_profiles allows admins to update (for main_service_id)
-- If it already has RLS, we need to make sure admins can UPDATE it.
CREATE POLICY "Admins can update technician_profiles"
ON public.technician_profiles
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);
