-- ==============================================================================
-- Fresh Home: Supabase Storage Setup for Settlement Proofs
-- File: 62_storage_setup.sql
-- Description: Creates a new public storage bucket named 'settlement_proofs'
--              and sets up RLS policies for Technicians (INSERT) and Admins (SELECT/UPDATE).
-- ==============================================================================

-- ── 1. CREATE STORAGE BUCKET ──────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('settlement_proofs', 'settlement_proofs', true)
ON CONFLICT (id) DO NOTHING;

-- ── 2. CREATE RLS POLICIES FOR SETTLEMENT PROOFS ─────────────────────────────

-- Policy A: Allow authenticated technicians to INSERT (upload) proof images
DROP POLICY IF EXISTS "Allow authenticated technicians to upload settlement proofs" ON storage.objects;
CREATE POLICY "Allow authenticated technicians to upload settlement proofs" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'settlement_proofs'
    );

-- Policy B: Allow Admins to SELECT (view) settlement proofs
DROP POLICY IF EXISTS "Allow admins to view settlement proofs" ON storage.objects;
CREATE POLICY "Allow admins to view settlement proofs" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'settlement_proofs' AND public.is_admin()
    );

-- Policy C: Allow Admins to UPDATE settlement proofs
DROP POLICY IF EXISTS "Allow admins to update settlement proofs" ON storage.objects;
CREATE POLICY "Allow admins to update settlement proofs" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'settlement_proofs' AND public.is_admin()
    )
    WITH CHECK (
        bucket_id = 'settlement_proofs' AND public.is_admin()
    );
