-- ==============================================================================
-- Fresh Home: Reviews & Ratings Business Logic
-- Migration ID: 73_reviews_logic
-- Description: Implement review submission and approval functions along with
--              automatic average rating synchronization triggers.
-- ==============================================================================

BEGIN;

-- 1. Create trigger function to automatically update technician average rating
CREATE OR REPLACE FUNCTION public.fn_sync_technician_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_avg_rating DECIMAL(3,2);
    v_tech_id    UUID;
BEGIN
    -- Determine target technician user_id based on operation
    IF TG_OP = 'DELETE' THEN
        v_tech_id := OLD.technician_id;
    ELSE
        v_tech_id := NEW.technician_id;
    END IF;

    -- Calculate average rating based on published reviews only
    SELECT ROUND(COALESCE(AVG(rating_value), 5.0), 2)
    INTO v_avg_rating
    FROM public.reviews
    WHERE technician_id = v_tech_id AND status = 'published';

    -- Update the technician profile rating
    UPDATE public.technician_profiles
    SET rating = v_avg_rating,
        updated_at = NOW()
    WHERE user_id = v_tech_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Attach the trigger to reviews table
DROP TRIGGER IF EXISTS trg_sync_technician_rating ON public.reviews;
CREATE TRIGGER trg_sync_technician_rating
    AFTER INSERT OR UPDATE OR DELETE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_sync_technician_rating();


-- 3. Create the submit_review RPC function
CREATE OR REPLACE FUNCTION public.submit_review(
    p_booking_id    UUID,
    p_rating_value  INTEGER,
    p_feedback_text TEXT
) RETURNS UUID AS $$
DECLARE
    v_booking_status public.order_status_v2;
    v_customer_id    UUID;
    v_tech_id        UUID;
    v_service_id     TEXT;
    v_status         TEXT;
    v_review_id      UUID;
BEGIN
    -- A. Fetch booking details
    SELECT status, user_id, technician_id, service_id
    INTO v_booking_status, v_customer_id, v_tech_id, v_service_id
    FROM public.bookings
    WHERE id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'BOOKING_NOT_FOUND' USING DETAIL = 'The requested booking does not exist.';
    END IF;

    -- B. Validate that the booking status is completed
    IF v_booking_status IS DISTINCT FROM 'completed'::public.order_status_v2 THEN
        RAISE EXCEPTION 'BOOKING_NOT_COMPLETED' USING DETAIL = 'Only completed bookings can be reviewed.';
    END IF;

    -- C. Validate that the caller is the customer who made the booking
    IF auth.uid() IS NULL OR v_customer_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'UNAUTHORIZED' USING DETAIL = 'Only the customer associated with this booking can review it.';
    END IF;

    -- D. Validate that the booking has not been reviewed yet
    IF EXISTS (SELECT 1 FROM public.reviews WHERE booking_id = p_booking_id) THEN
        RAISE EXCEPTION 'BOOKING_ALREADY_REVIEWED' USING DETAIL = 'This booking has already been reviewed.';
    END IF;

    -- E. Ensure a technician was assigned to this booking
    IF v_tech_id IS NULL THEN
        RAISE EXCEPTION 'NO_TECHNICIAN_ASSIGNED' USING DETAIL = 'No technician is associated with this booking.';
    END IF;

    -- F. Automatically assign review status: published (rating >= 4), quarantined (rating <= 3)
    IF p_rating_value >= 4 THEN
        v_status := 'published';
    ELSE
        v_status := 'quarantined';
    END IF;

    -- G. Insert review record (triggers rating recalculation automatically)
    INSERT INTO public.reviews (
        booking_id,
        customer_id,
        technician_id,
        service_id,
        rating_value,
        feedback_text,
        status
    ) VALUES (
        p_booking_id,
        v_customer_id,
        v_tech_id,
        v_service_id,
        p_rating_value,
        p_feedback_text,
        v_status
    )
    RETURNING id INTO v_review_id;

    RETURN v_review_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;


-- 4. Create the approve_review RPC function (Admins Only)
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

    -- D. Update status to published (triggers rating recalculation automatically)
    UPDATE public.reviews
    SET status = 'published'
    WHERE id = p_review_id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public;

COMMIT;
