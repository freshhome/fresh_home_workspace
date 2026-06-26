-- Migration ID: 81_create_active_services_tree_view
-- Description: Create a recursive view for active/paused services that automatically resolves hierarchical visibility.

BEGIN;

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

COMMIT;
