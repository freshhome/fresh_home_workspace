-- Migration ID: 84_add_payment_method_check_constraint
-- Description: Add CHECK constraint on bookings.payment_method to prevent invalid inputs.

BEGIN;

ALTER TABLE public.bookings 
DROP CONSTRAINT IF EXISTS chk_booking_payment_method;

ALTER TABLE public.bookings 
ADD CONSTRAINT chk_booking_payment_method 
CHECK (payment_method IS NULL OR payment_method IN ('cash', 'instapay', 'vodafone_cash'));

COMMIT;
