-- Description: Add created_at column to get_guest_booking_details RPC to allow guest tracking countdown timers.

CREATE OR REPLACE FUNCTION public.get_guest_booking_details(p_booking_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking RECORD;
    v_tech_name TEXT := NULL;
    v_tech_rating NUMERIC(3,2) := 5.0;
    v_tech_jobs INTEGER := 0;
BEGIN
    SELECT b.* INTO v_booking
    FROM public.bookings b
    WHERE b.id = p_booking_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Fetch technician details if assigned
    IF v_booking.technician_id IS NOT NULL THEN
        SELECT p.first_name || ' ' || p.last_name, tp.rating, tp.completed_jobs
        INTO v_tech_name, v_tech_rating, v_tech_jobs
        FROM public.profiles p
        LEFT JOIN public.technician_profiles tp ON tp.user_id = p.id
        WHERE p.id = v_booking.technician_id;
    END IF;

    RETURN jsonb_build_object(
        'id', v_booking.id,
        'readable_id', v_booking.readable_id,
        'status', v_booking.status,
        'created_at', v_booking.created_at,
        'scheduled_day', v_booking.scheduled_day,
        'start_time_slot', v_booking.start_time_slot,
        'address_snapshot', v_booking.address_snapshot,
        'service_snapshot', v_booking.service_snapshot,
        'price_snapshot', v_booking.price_snapshot,
        'contact_name', v_booking.contact_name,
        'contact_phones', v_booking.contact_phones,
        'is_whatsapp_confirmed', v_booking.is_whatsapp_confirmed,
        'technician_id', v_booking.technician_id,
        'technician', CASE 
            WHEN v_booking.technician_id IS NOT NULL THEN 
                jsonb_build_object(
                    'name', COALESCE(v_tech_name, 'فني معتمد'),
                    'rating', COALESCE(v_tech_rating, 5.0),
                    'completed_jobs', COALESCE(v_tech_jobs, 0)
                )
            ELSE NULL 
        END
    );
END;
$$;
