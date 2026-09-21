-- ==============================================================================
-- Migration ID: 111_add_service_gallery
-- Description: Add gallery JSONB field to services, update active_services_tree view,
--              and reinforce RLS security policies on service_images bucket.
-- ==============================================================================

BEGIN;

-- 1. Add gallery column to services table
ALTER TABLE public.services 
ADD COLUMN IF NOT EXISTS gallery JSONB NOT NULL DEFAULT '[]'::JSONB;

-- 2. Update the recursive active_services_tree view to include gallery
DROP VIEW IF EXISTS public.active_services_tree CASCADE;

CREATE OR REPLACE VIEW public.active_services_tree 
WITH (security_invoker = true) AS
WITH RECURSIVE active_tree AS (
    -- Anchor member: root services that are active or paused
    SELECT 
        id, 
        parent_id, 
        is_bookable, 
        title, 
        description, 
        instructions, 
        image, 
        gallery,
        status, 
        sort_order, 
        price_config, 
        details, 
        not_included, 
        created_at, 
        updated_at
    FROM public.services
    WHERE parent_id IS NULL 
      AND status IN ('active'::public.service_status, 'paused'::public.service_status)
    
    UNION ALL
    
    -- Recursive member: child services that are active or paused and whose parent is in the active tree
    SELECT 
        s.id, 
        s.parent_id, 
        s.is_bookable, 
        s.title, 
        s.description, 
        s.instructions, 
        s.image, 
        s.gallery,
        s.status, 
        s.sort_order, 
        s.price_config, 
        s.details, 
        s.not_included, 
        s.created_at, 
        s.updated_at
    FROM public.services s
    INNER JOIN active_tree at ON s.parent_id = at.id
    WHERE s.status IN ('active'::public.service_status, 'paused'::public.service_status)
)
SELECT * FROM active_tree;

-- 3. Reinforce Storage RLS Policies for service_images bucket
-- Ensure bucket exists
INSERT INTO storage.buckets (id, name, public) 
VALUES ('service_images', 'service_images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- A. Anyone can view service images (Public SELECT)
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

COMMIT;
