-- ==============================================================================
-- Fresh Home: Auto-Acceptance Logic (Phase 5)
-- Description: Automatically accepts bookings that have been in 'assigned'
--              status for more than 1 hour without being declined.
-- ==============================================================================

-- 1. وظيفة القبول التلقائي للحجوزات "العالقة"
-- يمكن استدعاؤها دورياً (cron) أو برمجياً من السيرفر.
CREATE OR REPLACE FUNCTION public.auto_accept_stale_assignments()
RETURNS void AS $$
DECLARE
    v_booking_id UUID;
BEGIN
    FOR v_booking_id IN 
        SELECT id FROM public.bookings
        WHERE status = 'assigned'
        AND assigned_at < NOW() - INTERVAL '1 hour'
    LOOP
        -- تنفيذ الانتقال لكل طلب عالق
        -- نستخدم 'system' كممثل (actor) لهوية النظام
        PERFORM public.transition_booking(
            v_booking_id,
            'accepted',
            '00000000-0000-0000-0000-000000000000', -- System ID placeholder
            'admin', -- نستخدم 'admin' لتجاوز قيود الفني أثناء القبول التلقائي
            'Auto-accepted after 1 hour of silence.'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

COMMENT ON FUNCTION public.auto_accept_stale_assignments() 
IS 'Finds and accepts bookings in assigned status for > 1 hour.';
