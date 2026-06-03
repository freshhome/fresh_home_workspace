-- ==============================================================================
-- Fresh Home: Fix User Roles Policy Infinite Recursion
-- Migration ID: 53_fix_user_roles_recursion
-- Description: Re-creates all RLS policies checking admin roles using
--              the SECURITY DEFINER function public.is_admin() instead of
--              recursive SELECT queries on public.user_roles.
-- ==============================================================================

BEGIN;

-- 1. Ensure the is_admin() helper is defined correctly as SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles ur 
        JOIN public.roles r ON ur.role_id = r.id 
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    );
END; $$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Update public.user_roles policies
DROP POLICY IF EXISTS "Admins can view and manage all user roles" ON public.user_roles;
CREATE POLICY "Admins can view and manage all user roles" ON public.user_roles
    FOR ALL USING (
        public.is_admin()
    );

-- 3. Update public.profiles policies
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles" ON public.profiles
    FOR ALL USING (
        public.is_admin()
    );

-- 4. Update public.user_phones policies
DROP POLICY IF EXISTS "Admins can view all user phones" ON public.user_phones;
CREATE POLICY "Admins can view all user phones" ON public.user_phones
    FOR SELECT USING (
        public.is_admin()
    );

-- 5. Update public.user_addresses policies
DROP POLICY IF EXISTS "Admins can view all user addresses" ON public.user_addresses;
CREATE POLICY "Admins can view all user addresses" ON public.user_addresses
    FOR SELECT USING (
        public.is_admin()
    );

-- 6. Update public.technician_profiles policies
DROP POLICY IF EXISTS "Admins have full access on technician profiles" ON public.technician_profiles;
CREATE POLICY "Admins have full access on technician profiles" ON public.technician_profiles
    FOR ALL USING (
        public.is_admin()
    );

-- 7. Update public.services policies
DROP POLICY IF EXISTS "Admins can manage services" ON public.services;
CREATE POLICY "Admins can manage services"
ON public.services
FOR ALL
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);

-- 8. Update public.shared_icons policies
DROP POLICY IF EXISTS "Admins can manage shared icons" ON public.shared_icons;
CREATE POLICY "Admins can manage shared icons"
ON public.shared_icons FOR ALL
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);

-- 9. Update public.bookings policies
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
CREATE POLICY "Admins can view all bookings" ON public.bookings
    FOR SELECT USING (
        public.is_admin()
    );

DROP POLICY IF EXISTS "Admins can update all bookings" ON public.bookings;
CREATE POLICY "Admins can update all bookings" ON public.bookings
    FOR UPDATE USING (
        public.is_admin()
    ) WITH CHECK (
        public.is_admin()
    );

DROP POLICY IF EXISTS "Admins can delete bookings" ON public.bookings;
CREATE POLICY "Admins can delete bookings" ON public.bookings
    FOR DELETE USING (
        public.is_admin()
    );

DROP POLICY IF EXISTS "Admins can insert bookings" ON public.bookings;
CREATE POLICY "Admins can insert bookings" ON public.bookings
    FOR INSERT WITH CHECK (
        public.is_admin()
    );

-- 10. Update public.capacity_overrides policies
DROP POLICY IF EXISTS "Admins can do everything on capacity_overrides" ON public.capacity_overrides;
CREATE POLICY "Admins can do everything on capacity_overrides" ON public.capacity_overrides
    FOR ALL USING (
        public.is_admin()
    );

-- 11. Update public.user_fcm_tokens policies
DROP POLICY IF EXISTS "Admins can read all FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Admins can read all FCM tokens" ON public.user_fcm_tokens
    FOR SELECT USING (
        public.is_admin()
    );

-- 12. Update public.notification_campaigns policies
DROP POLICY IF EXISTS "Admins can manage notification campaigns" ON public.notification_campaigns;
CREATE POLICY "Admins can manage notification campaigns" ON public.notification_campaigns
    FOR ALL USING (
        public.is_admin()
    );

-- 13. Update storage.objects policies (service_images & notification_images)
DROP POLICY IF EXISTS "Admins can insert service images" ON storage.objects;
CREATE POLICY "Admins can insert service images" 
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'service_images' 
    AND public.is_admin()
);

DROP POLICY IF EXISTS "Admins can update service images" ON storage.objects;
CREATE POLICY "Admins can update service images" 
ON storage.objects FOR UPDATE 
USING (
    bucket_id = 'service_images' 
    AND public.is_admin()
);

DROP POLICY IF EXISTS "Admins can delete service images" ON storage.objects;
CREATE POLICY "Admins can delete service images" 
ON storage.objects FOR DELETE 
USING (
    bucket_id = 'service_images' 
    AND public.is_admin()
);

DROP POLICY IF EXISTS "Admins can insert notification images" ON storage.objects;
CREATE POLICY "Admins can insert notification images" 
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'notification_images' 
    AND public.is_admin()
);

COMMIT;
