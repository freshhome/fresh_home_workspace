-- ==============================================================================
-- Fresh Home: Reviews Remediation Setup
-- Migration ID: 74_remediation_reviews
-- Description: Applies security hardening constraints, updates approve_review
--              with audit trails, and creates a consolidated security-invoker
--              view to optimize loading performance.
-- ==============================================================================

BEGIN;

-- 1. Add UNIQUE constraint to reviews(booking_id) to prevent duplicate reviews
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS uq_reviews_booking_id;
ALTER TABLE public.reviews ADD CONSTRAINT uq_reviews_booking_id UNIQUE (booking_id);

-- 2. Add moderation audit columns to public.reviews table
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- 3. Update the approve_review RPC function to record audit trail
CREATE OR REPLACE FUNCTION public.approve_review(
    p_review_id UUID
) RETURNS VOID AS $$
DECLARE
    v_current_status TEXT;
BEGIN
    -- A. Enforce admin-only access
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'UNAUTHORIZED' USING DETAIL = 'Only administrators can approve quarantined reviews.';
    END IF;

    -- B. Fetch the review status
    SELECT status INTO v_current_status
    FROM public.reviews
    WHERE id = p_review_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'REVIEW_NOT_FOUND' USING DETAIL = 'Review does not exist.';
    END IF;

    -- C. Ensure the review is currently quarantined
    IF v_current_status IS DISTINCT FROM 'quarantined' THEN
        RAISE EXCEPTION 'INVALID_REVIEW_STATE' USING DETAIL = 'Only quarantined reviews can be approved.';
    END IF;

    -- D. Update status to published and record audit trail (triggers rating recalculation automatically)
    UPDATE public.reviews
    SET status = 'published',
        approved_by = auth.uid(),
        approved_at = NOW()
    WHERE id = p_review_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;

-- 4. Disable direct INSERT policy for customers on public.reviews
DROP POLICY IF EXISTS "Customers can insert their own reviews" ON public.reviews;

-- 5. Create SQL View to resolve N+1 loading problem (using security_invoker = true for security)
CREATE OR REPLACE VIEW public.view_reviews_with_details 
WITH (security_invoker = true) AS
SELECT 
    r.id,
    r.booking_id,
    r.customer_id,
    r.technician_id,
    r.service_id,
    r.rating_value,
    r.feedback_text,
    r.status,
    r.created_at,
    r.approved_by,
    r.approved_at,
    s.title AS service_title,
    s.image AS service_image,
    tp.first_name AS technician_first_name,
    tp.last_name AS technician_last_name,
    tp.avatar_url AS technician_avatar_url,
    cp.first_name AS customer_first_name,
    cp.last_name AS customer_last_name,
    cp.avatar_url AS customer_avatar_url
FROM public.reviews r
JOIN public.services s ON r.service_id = s.id
JOIN public.profiles tp ON r.technician_id = tp.id
JOIN public.profiles cp ON r.customer_id = cp.id;

COMMIT;
