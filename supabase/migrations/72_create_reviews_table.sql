-- ==============================================================================
-- Fresh Home: Reviews Table & RLS Policies Setup
-- Migration ID: 72_create_reviews_table
-- Description: Creates the public.reviews table with constraints and configures RLS.
-- ==============================================================================

BEGIN;

-- 1. Create the public.reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id    UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    customer_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    technician_id UUID NOT NULL REFERENCES public.technician_profiles(user_id) ON DELETE CASCADE,
    service_id    TEXT NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
    
    -- rating_value check constraint (1 to 5 stars)
    rating_value  INTEGER NOT NULL CONSTRAINT chk_reviews_rating_range CHECK (rating_value BETWEEN 1 AND 5),
    
    feedback_text TEXT,
    
    -- status check constraint ('published' or 'quarantined')
    status        TEXT NOT NULL CONSTRAINT chk_reviews_status CHECK (status IN ('published', 'quarantined')),
    
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create indexes for foreign keys and lookup queries to optimize performance
CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON public.reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON public.reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_technician_id ON public.reviews(technician_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON public.reviews(status);
CREATE INDEX IF NOT EXISTS idx_reviews_service_id ON public.reviews(service_id);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 4. Define RLS Policies for public.reviews

-- A. Admins: Full access (Select, Insert, Update, Delete)
DROP POLICY IF EXISTS "Admins have full access on reviews" ON public.reviews;
CREATE POLICY "Admins have full access on reviews" ON public.reviews
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- B. Customers: Can view their own reviews
DROP POLICY IF EXISTS "Customers can view their own reviews" ON public.reviews;
CREATE POLICY "Customers can view their own reviews" ON public.reviews
    FOR SELECT
    USING (auth.uid() = customer_id);

-- C. Customers: Can insert their own reviews
DROP POLICY IF EXISTS "Customers can insert their own reviews" ON public.reviews;
CREATE POLICY "Customers can insert their own reviews" ON public.reviews
    FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- D. Technicians: Can view published reviews related to them
DROP POLICY IF EXISTS "Technicians can view their own published reviews" ON public.reviews;
CREATE POLICY "Technicians can view their own published reviews" ON public.reviews
    FOR SELECT
    USING (auth.uid() = technician_id AND status = 'published');

COMMIT;
