-- ==============================================================================
-- Fresh Home: Capacity Overrides RLS Policies
-- Description: Enables technicians to manage their own capacity overrides.
-- ==============================================================================

-- 1. Enable RLS
ALTER TABLE public.capacity_overrides ENABLE ROW LEVEL SECURITY;

-- 2. ADMIN POLICY: Full access for administrators
DROP POLICY IF EXISTS "Admins can do everything on capacity_overrides" ON public.capacity_overrides;
CREATE POLICY "Admins can do everything on capacity_overrides"
ON public.capacity_overrides
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- 3. TECHNICIAN POLICY: Technicians can view and manage their own overrides
-- This allows technicians to perform SELECT, INSERT, UPDATE, and DELETE on their own rows.
-- This is critical for the 'upsert' operation used in the mobile app.
DROP POLICY IF EXISTS "Technicians can manage own capacity_overrides" ON public.capacity_overrides;
CREATE POLICY "Technicians can manage own capacity_overrides"
ON public.capacity_overrides
FOR ALL
USING (auth.uid() = technician_id)
WITH CHECK (auth.uid() = technician_id);

-- 4. Ensure capacity_pools also allows technicians to read (already should be there, but double check)
-- This is needed because the app checks pool_id before upserting.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'capacity_pools' 
        AND policyname = 'Technicians can read own capacity_pools'
    ) THEN
        CREATE POLICY "Technicians can read own capacity_pools"
        ON public.capacity_pools
        FOR SELECT
        USING (auth.uid() = technician_id);
    END IF;
END $$;
