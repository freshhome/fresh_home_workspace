-- ==============================================================================
-- Rollback Migration: 97_address_system_v2_schema_rollback.sql
-- Description: Clean rollback script for Address System V2 Schema
-- Author: Principal Architect
-- ==============================================================================

-- 1. DROP TRIGGERS AND TRIGGER FUNCTIONS
DROP TRIGGER IF EXISTS trg_handle_primary_address_switch ON public.user_addresses;
DROP TRIGGER IF EXISTS trg_user_addresses_updated_at ON public.user_addresses;
DROP FUNCTION IF EXISTS public.fn_handle_primary_address_switch();
DROP FUNCTION IF EXISTS public.fn_update_user_addresses_updated_at();

-- 2. DROP RLS POLICIES
DROP POLICY IF EXISTS "Technicians can view addresses of assigned bookings" ON public.user_addresses;
DROP POLICY IF EXISTS "Admins can view all addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can delete their own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can update their own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can insert their own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can view their own non-deleted addresses" ON public.user_addresses;

-- 3. DROP INDEXES AND CONSTRAINTS
DROP INDEX IF EXISTS public.idx_user_addresses_lookup;
DROP INDEX IF EXISTS public.idx_user_addresses_user_id;
DROP INDEX IF EXISTS public.idx_user_primary_address;

ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_longitude_range;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_latitude_range;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_building_identifier_length;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_street_or_compound_length;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_district_length;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_city_length;
ALTER TABLE public.user_addresses DROP CONSTRAINT IF EXISTS chk_governorate_length;

-- 4. CLEANUP BACKUP TABLE IF CREATED
DROP TABLE IF EXISTS public.user_addresses_v2_backup;
