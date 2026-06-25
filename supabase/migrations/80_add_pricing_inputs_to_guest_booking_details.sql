-- Migration ID: 80_add_pricing_inputs_to_guest_booking_details
-- Description: Re-create public.get_guest_booking_details(p_booking_id UUID) to include pricing_inputs and price_config in returned JSONB object.

BEGIN;

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
    v_price_config JSONB := NULL;
BEGIN
    SELECT b.* INTO v_booking
    FROM public.bookings b
    WHERE b.id = p_booking_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Fetch price configuration of the sub-service to map inputs and options properly
    SELECT s.price_config INTO v_price_config
    FROM public.services s
    WHERE s.id = v_booking.service_id;

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
        'pricing_inputs', v_booking.pricing_inputs,
        'price_config', v_price_config,
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

GRANT EXECUTE ON FUNCTION public.get_guest_booking_details(UUID) TO anon, authenticated;

COMMIT;
