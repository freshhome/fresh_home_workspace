-- ==============================================================================
-- Fresh Home: Admin FCM Tokens RPC Function (Phase 8.1)
-- Problem: The client-side query on user_fcm_tokens fails due to:
--   1. RLS blocking the admin from reading other users' tokens
--   2. The join to `profiles` fails because user_fcm_tokens.user_id references
--      auth.users(id), not profiles(id) directly — Supabase can't resolve
--      the relationship automatically through the JS client join syntax.
-- Fix: A SECURITY DEFINER RPC function that runs server-side with elevated
--      privileges. It validates the caller is an admin before returning data.
-- ==============================================================================

-- 1. Also fix RLS policies while we're here (belt-and-suspenders)
DROP POLICY IF EXISTS "Users can manage their own tokens" ON public.user_fcm_tokens;

CREATE POLICY IF NOT EXISTS "Users can select own tokens"
ON public.user_fcm_tokens FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can manage own tokens"
ON public.user_fcm_tokens FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Admins can read all FCM tokens"
ON public.user_fcm_tokens FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
      AND r.name = 'admin'
  )
);

-- 2. Create the secure RPC function for the admin test lab
--    SECURITY DEFINER = runs as the function owner (postgres),
--    bypassing RLS on all tables. The admin check inside is the security gate.
CREATE OR REPLACE FUNCTION public.get_all_fcm_tokens_for_admin()
RETURNS TABLE (
  user_id     UUID,
  fcm_token   TEXT,
  platform    TEXT,
  updated_at  TIMESTAMPTZ,
  first_name  TEXT,
  last_name   TEXT,
  email       TEXT,
  roles       TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- ✅ Security Gate: only admins can call this function
  IF NOT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
      AND r.name = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  -- Return all FCM tokens joined with profile and role info
  RETURN QUERY
  SELECT
    t.user_id,
    t.fcm_token,
    t.platform,
    t.updated_at,
    COALESCE(p.first_name, '')  AS first_name,
    COALESCE(p.last_name, '')   AS last_name,
    COALESCE(p.email, '')       AS email,
    COALESCE(
      ARRAY_AGG(DISTINCT r2.name) FILTER (WHERE r2.name IS NOT NULL),
      ARRAY['client']
    ) AS roles
  FROM public.user_fcm_tokens t
  LEFT JOIN public.profiles p       ON p.id = t.user_id
  LEFT JOIN public.user_roles ur2   ON ur2.user_id = t.user_id
  LEFT JOIN public.roles r2         ON r2.id = ur2.role_id
  GROUP BY t.user_id, t.fcm_token, t.platform, t.updated_at, p.first_name, p.last_name, p.email
  ORDER BY t.updated_at DESC
  LIMIT 50;
END;
$$;

-- Grant execute permission to authenticated users
-- (the admin check inside the function is the actual security layer)
GRANT EXECUTE ON FUNCTION public.get_all_fcm_tokens_for_admin() TO authenticated;
