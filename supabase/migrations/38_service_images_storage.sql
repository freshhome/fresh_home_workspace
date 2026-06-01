-- ==============================================================================
-- Fresh Home: Service Images Storage Bucket & Policies
-- Migration ID: 38_service_images_storage
-- ==============================================================================

-- 1. Create storage bucket for service images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('service_images', 'service_images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. RLS Policies for service_images bucket

-- A. Anyone can view service images
DROP POLICY IF EXISTS "Anyone can view service images" ON storage.objects;
CREATE POLICY "Anyone can view service images"
ON storage.objects FOR SELECT
USING (bucket_id = 'service_images');

-- B. Admins can insert service images
DROP POLICY IF EXISTS "Admins can insert service images" ON storage.objects;
CREATE POLICY "Admins can insert service images" 
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'service_images' 
    AND EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- C. Admins can update service images
DROP POLICY IF EXISTS "Admins can update service images" ON storage.objects;
CREATE POLICY "Admins can update service images" 
ON storage.objects FOR UPDATE 
USING (
    bucket_id = 'service_images' 
    AND EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- D. Admins can delete service images
DROP POLICY IF EXISTS "Admins can delete service images" ON storage.objects;
CREATE POLICY "Admins can delete service images" 
ON storage.objects FOR DELETE 
USING (
    bucket_id = 'service_images' 
    AND EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);
