-- ==============================================================================
-- Fresh Home: Relax Bookable to Non-Bookable Type Violations
-- Migration ID: 36_relax_bookable_integrity
-- Description: Allow changing a service from bookable to non-bookable if there
-- are no referencing bookings or technician skills associated with it.
-- ==============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_check_service_tree_integrity()
RETURNS TRIGGER AS $$
BEGIN
    -- A. Prevent changing a service from bookable to non-bookable ONLY if it has active bookings or technician skills
    IF TG_OP = 'UPDATE' AND OLD.is_bookable = true AND NEW.is_bookable = false THEN
        IF EXISTS (SELECT 1 FROM public.bookings WHERE service_id = OLD.id LIMIT 1) THEN
            RAISE EXCEPTION 'Cannot change service to non-bookable because it has associated bookings.' 
                USING ERRCODE = 'P0008';
        END IF;

        IF EXISTS (SELECT 1 FROM public.technician_skills WHERE sub_service_id = OLD.id LIMIT 1) THEN
            RAISE EXCEPTION 'Cannot change service to non-bookable because it has associated technician skills.' 
                USING ERRCODE = 'P0008';
        END IF;
        
        -- Safe to change: Clean up price_config, details, and not_included fields automatically
        NEW.price_config := NULL;
        NEW.details := '[]'::JSONB;
        NEW.not_included := '{}'::JSONB;
    END IF;

    -- B. On update, if service is marked as is_bookable = true, verify it has no child nodes
    IF TG_OP = 'UPDATE' AND NEW.is_bookable = true THEN
        IF EXISTS (SELECT 1 FROM public.services WHERE parent_id = NEW.id LIMIT 1) THEN
            RAISE EXCEPTION 'Cannot mark service as bookable because it has sub-categories.' 
                USING ERRCODE = 'P0005';
        END IF;
    END IF;

    -- C. Verify that the parent node (if assigned) is NOT bookable
    IF NEW.parent_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM public.services WHERE id = NEW.parent_id AND is_bookable = true LIMIT 1) THEN
            RAISE EXCEPTION 'Cannot assign a parent that is marked as bookable.' 
                USING ERRCODE = 'P0006';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;
