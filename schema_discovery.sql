-- Run this in Supabase SQL Editor to see the ACTUAL column structure of your bookings table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'bookings'
ORDER BY ordinal_position;
