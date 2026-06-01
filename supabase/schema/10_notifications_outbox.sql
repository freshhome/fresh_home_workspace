-- ==============================================================================
-- Fresh Home: Notifications Outbox System (v1.0)
-- Description: Reliable Outbox pattern for decoupled notification delivery.
-- ==============================================================================

-- 1. Create Outbox Table
CREATE TYPE public.notification_recipient_type AS ENUM ('customer', 'technician', 'admin');
CREATE TYPE public.notification_outbox_status AS ENUM ('pending', 'sent', 'failed');

CREATE TABLE IF NOT EXISTS public.notifications_outbox (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      TEXT NOT NULL,
    recipient_type  public.notification_recipient_type NOT NULL,
    recipient_id    UUID, -- Can be NULL for system-wide or multi-recipient alerts
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB DEFAULT '{}'::jsonb, -- Payload for deep linking, booking_id, etc.
    status          public.notification_outbox_status DEFAULT 'pending',
    retry_count     INTEGER DEFAULT 0,
    error_message   TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at         TIMESTAMP WITH TIME ZONE,
    processed_at    TIMESTAMP WITH TIME ZONE
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_notifications_outbox_status ON public.notifications_outbox(status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_notifications_outbox_created_at ON public.notifications_outbox(created_at);

-- 2. Helper: Enqueue Notification
CREATE OR REPLACE FUNCTION public.enqueue_notification(
    p_event_type      TEXT,
    p_recipient_type  public.notification_recipient_type,
    p_recipient_id    UUID,
    p_title           TEXT,
    p_body            TEXT,
    p_data            JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_outbox_id UUID;
BEGIN
    INSERT INTO public.notifications_outbox (
        event_type,
        recipient_type,
        recipient_id,
        title,
        body,
        data
    )
    VALUES (
        p_event_type,
        p_recipient_type,
        p_recipient_id,
        p_title,
        p_body,
        p_data
    )
    RETURNING id INTO v_outbox_id;
    
    RETURN v_outbox_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
