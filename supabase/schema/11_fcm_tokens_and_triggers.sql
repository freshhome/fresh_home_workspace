-- ==============================================================================
-- Fresh Home: FCM Token Management & Notification Triggers (Phase 5)
-- Description: Table for storing FCM tokens and trigger for Edge Function.
-- ==============================================================================

-- 1. Create user_fcm_tokens table
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id   TEXT NOT NULL,
    fcm_token   TEXT NOT NULL,
    platform    TEXT NOT NULL, -- 'ios' | 'android' | 'web'
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

-- Enable RLS
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can manage their own tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can manage their own tokens"
ON public.user_fcm_tokens FOR ALL
USING (auth.uid() = user_id);

-- 2. Upsert FCM Token Function
CREATE OR REPLACE FUNCTION public.upsert_fcm_token(
    p_device_id  TEXT,
    p_fcm_token  TEXT,
    p_platform   TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.user_fcm_tokens (user_id, device_id, fcm_token, platform, updated_at)
    VALUES (auth.uid(), p_device_id, p_fcm_token, p_platform, NOW())
    ON CONFLICT (user_id, device_id) 
    DO UPDATE SET 
        fcm_token = EXCLUDED.fcm_token,
        platform  = EXCLUDED.platform,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Worker Delivery View
-- This view consolidates pending notifications with their target tokens
CREATE OR REPLACE VIEW public.v_pending_notifications AS
SELECT 
    n.id as outbox_id,
    n.recipient_id,
    n.title,
    n.body,
    n.data,
    t.fcm_token,
    t.platform
FROM public.notifications_outbox n
JOIN public.user_fcm_tokens t ON n.recipient_id = t.user_id
WHERE n.status = 'pending' 
  AND n.retry_count < 5;

COMMENT ON TABLE public.user_fcm_tokens IS 'Stores valid FCM tokens for multi-device push notification delivery.';
COMMENT ON VIEW public.v_pending_notifications IS 'Optimized view for the Edge Function worker to fetch delivery tasks.';
