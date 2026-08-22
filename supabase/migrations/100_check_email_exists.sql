-- ==============================================================================
-- Fresh Home: Migration 100 - Check Email Exists RPC
-- Target: Verify if an email is registered in auth.users before password reset
-- ==============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.check_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users 
        WHERE LOWER(email) = LOWER(TRIM(p_email))
    );
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO anon, authenticated, service_role;

COMMIT;
