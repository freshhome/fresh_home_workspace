-- 1. إضافة عمود إثبات التحويل الخاص بالإدارة إلى جدول طلبات التسوية
ALTER TABLE public.settlement_requests 
ADD COLUMN IF NOT EXISTS admin_proof_url TEXT;

-- 2. إقرار سياسة RLS لتمكين المسؤولين من رفع الملفات لباكت settlement_proofs
DROP POLICY IF EXISTS "Allow admins to upload settlement proofs" ON storage.objects;
CREATE POLICY "Allow admins to upload settlement proofs" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'settlement_proofs' AND public.is_admin()
    );
