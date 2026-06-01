-- ==============================================================================
-- Fresh Home: Availability Diagnostic & Fix Script
-- Run this in your Supabase SQL Editor to troubleshoot "All Days Full"
-- ==============================================================================

-- 1. Check Technician Capabilities Mapping
SELECT 
    ss.title->>'en' as service_name,
    count(ts.id) as linked_technicians,
    count(ts.id) FILTER (WHERE ts.is_active = true) as active_mappings
FROM public.services ss
LEFT JOIN public.technician_skills ts ON ss.id = ts.sub_service_id
WHERE ss.is_bookable = true
GROUP BY ss.id, ss.title;

-- 2. Check Technician Availability Status
SELECT 
    p.first_name, 
    p.last_name, 
    p.account_status,
    tp.is_available as technician_ready,
    tp.rating
FROM public.profiles p
JOIN public.technician_profiles tp ON p.id = tp.user_id;

-- 3. EMERGENCY FIX: Make all technicians available and active (FOR TESTING ONLY)
-- Uncomment the lines below to apply the fix:

/*
-- A. Mark all existing technicians as available and active
UPDATE public.profiles SET account_status = 'active' WHERE id IN (SELECT user_id FROM public.technician_profiles);
UPDATE public.technician_profiles SET is_available = true;
*/

-- 4. TEST THE RPC DIRECTLY for a specific bookable service
-- Replace 'YOUR_SERVICE_ID_HERE' with an actual UUID from Step 1
-- SELECT * FROM public.get_available_days('YOUR_SERVICE_ID_HERE', CURRENT_DATE, (CURRENT_DATE + INTERVAL '30 days')::DATE);
