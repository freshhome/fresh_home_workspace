-- Migration ID: 65_add_booking_update_rls_policies
-- Description: Add RLS update policies for technicians and clients on public.bookings table to allow updating pricing_inputs.

BEGIN;

-- 1. Drop existing policies if they exist (to avoid duplication conflicts)
DROP POLICY IF EXISTS "Technicians can update their assigned bookings" ON public.bookings;
DROP POLICY IF EXISTS "Customers can update their own bookings" ON public.bookings;

-- 2. Create update policy for technicians
-- Allows technicians to update bookings assigned to them (used for pricing inputs and cash collection)
CREATE POLICY "Technicians can update their assigned bookings" ON public.bookings
    FOR UPDATE
    USING (auth.uid() = technician_id)
    WITH CHECK (auth.uid() = technician_id);

-- 3. Create update policy for customers
-- Allows customers to update bookings they created (used for schedule, address, etc.)
CREATE POLICY "Customers can update their own bookings" ON public.bookings
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

COMMIT;
