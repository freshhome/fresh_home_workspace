-- ==============================================================================
-- Fresh Home: Realtime & Security Configuration (v2.3)
-- Description: Ensures bookings are visible and synchronized in real-time
-- ==============================================================================

-- 1. ENABLE REALTIME for the bookings table
-- Note: Supabase requires manual entry into the 'supabase_realtime' publication
DO $$
BEGIN
  -- Add the table to the publication if it's not already there
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;
END $$;

-- 2. CONFIGURE ROW LEVEL SECURITY (RLS)
-- This ensures users can ONLY see their own bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own bookings
DROP POLICY IF EXISTS "Users can view their own bookings" ON public.bookings;
CREATE POLICY "Users can view their own bookings" ON public.bookings
FOR SELECT USING (auth.uid() = user_id);

-- Policy: Technicians can view bookings assigned to them
DROP POLICY IF EXISTS "Technicians can view their assigned bookings" ON public.bookings;
CREATE POLICY "Technicians can view their assigned bookings" ON public.bookings
FOR SELECT USING (auth.uid() = technician_id);

-- Policy: Users can create their own bookings (Disabled to force create_atomic_booking RPC)
DROP POLICY IF EXISTS "Users can create their own bookings" ON public.bookings;

-- 3. DIANOSTIC: Check if there are any orphan bookings with wrong user_id
-- (Optional) Run this to see if bookings exist but belong to a different ID
-- SELECT id, user_id, readable_id FROM public.bookings;
