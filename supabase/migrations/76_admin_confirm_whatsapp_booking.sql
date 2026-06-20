-- Migration ID: 76_admin_confirm_whatsapp_booking
-- Description: Add public.admin_confirm_whatsapp_booking RPC to allow admins to confirm a booking manually.

BEGIN;

CREATE OR REPLACE FUNCTION public.admin_confirm_whatsapp_booking(p_booking_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Verify actor is an admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can manually confirm bookings.' USING ERRCODE = '42501';
    END IF;

    -- Update is_whatsapp_confirmed and clear expiry
    UPDATE public.bookings
    SET 
        is_whatsapp_confirmed = true,
        whatsapp_confirmation_expires_at = NULL,
        updated_at = NOW()
    WHERE id = p_booking_id;

    -- Insert event in log
    INSERT INTO public.booking_events (booking_id, event_type, actor_id, actor_role, metadata)
    VALUES (
        p_booking_id,
        'WHATSAPP_CONFIRMED',
        auth.uid(),
        'admin',
        '{"method": "admin_manual"}'::jsonb
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMIT;
