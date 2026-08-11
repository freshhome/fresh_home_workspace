-- Fresh Home Address System V2 - Phase 4.4
-- Migration 99: Address Snapshot V2 Contract Documentation
-- Ensures address_snapshot column contract is formally documented for immutable V2 JSON snapshots.

COMMENT ON COLUMN public.bookings.address_snapshot IS 
'Versioned immutable address snapshot (V2 format supports bilingual governorate_ar/en, city_ar/en, district_ar/en, and reference IDs governorate_id, city_id, district_id).';
