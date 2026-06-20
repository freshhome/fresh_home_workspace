-- ==============================================================================
-- Fresh Home: Patch Technician Rating RLS Vulnerability
-- Migration ID: 71_patch_technician_rating_rls
-- Description: Adds a trigger to prevent non-admins from modifying rating and
--              completed_jobs columns on technician profiles.
-- ==============================================================================

BEGIN;

-- 1. Create trigger function to enforce read-only columns for rating and completed_jobs
CREATE OR REPLACE FUNCTION public.fn_prevent_technician_rating_override()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if rating or completed_jobs is being modified
    IF (OLD.rating IS DISTINCT FROM NEW.rating OR OLD.completed_jobs IS DISTINCT FROM NEW.completed_jobs) THEN
        -- Only block if the update is coming from a direct PostgREST client call (authenticated or anon role)
        -- and the user is NOT an administrator
        IF CURRENT_USER IN ('authenticated', 'anon') AND NOT public.is_admin() THEN
            RAISE EXCEPTION 'Unauthorized: The rating and completed_jobs columns are read-only and can only be updated by the system or administrators.'
                USING ERRCODE = '42501';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Attach trigger to public.technician_profiles table
DROP TRIGGER IF EXISTS trg_prevent_technician_rating_override ON public.technician_profiles;
CREATE TRIGGER trg_prevent_technician_rating_override
    BEFORE UPDATE ON public.technician_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_prevent_technician_rating_override();

COMMIT;
