-- ==============================================================================
-- Fresh Home: Admin Notification Campaigns (Phase 8)
-- Description: Creates the campaigns table, storage bucket, cron scheduling, 
--              and webhook triggers for the Enterprise Notification Management.
-- ==============================================================================

-- 1. Create notification_campaigns table
CREATE TABLE IF NOT EXISTS public.notification_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    target_type TEXT NOT NULL CHECK (target_type IN ('all', 'customers', 'technicians', 'single_user', 'city', 'service', 'topic')),
    target_filter JSONB DEFAULT '{}'::jsonb, 
    deep_link TEXT,
    payload JSONB DEFAULT '{}'::jsonb,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('normal', 'high')),
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')),
    success_count INT DEFAULT 0,
    failure_count INT DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.notification_campaigns ENABLE ROW LEVEL SECURITY;

-- 2. RLS Policies
-- Note: Assuming the role logic relies on the JWT 'role' or a custom user_roles table.
DROP POLICY IF EXISTS "Admins can manage notification campaigns" ON public.notification_campaigns;
CREATE POLICY "Admins can manage notification campaigns"
ON public.notification_campaigns FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name = 'admin'
));

-- 3. Storage Bucket for Campaign Images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('notification_images', 'notification_images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Admins can select notification images" ON storage.objects;
CREATE POLICY "Admins can select notification images" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'notification_images');

DROP POLICY IF EXISTS "Admins can insert notification images" ON storage.objects;
CREATE POLICY "Admins can insert notification images" 
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'notification_images' 
    AND EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

DROP POLICY IF EXISTS "Anyone can view notification images" ON storage.objects;
CREATE POLICY "Anyone can view notification images"
ON storage.objects FOR SELECT
USING (bucket_id = 'notification_images');

-- 4. Enable pg_cron and Schedule Jobs
-- Note: Requires pg_cron extension, which may require direct Supabase dashboard access to enable if it fails via SQL.
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Check for due campaigns every minute and mark as 'sending'
-- The trigger below will intercept this change and fire the webhook
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'process-scheduled-campaigns') THEN
        PERFORM cron.schedule(
          'process-scheduled-campaigns', 
          '* * * * *', 
          'UPDATE public.notification_campaigns SET status = ''sending'' WHERE status = ''scheduled'' AND scheduled_at <= NOW()'
        );
    END IF;
END $$;


-- 5. RPC to Fetch Tokens per Campaign Targeting
CREATE OR REPLACE FUNCTION public.get_campaign_fcm_tokens(
    p_target_type TEXT, 
    p_target_filter JSONB
)
RETURNS TABLE (fcm_token TEXT) AS $$
BEGIN
    IF p_target_type = 'all' THEN
        RETURN QUERY SELECT t.fcm_token FROM public.user_fcm_tokens t;
    ELSIF p_target_type = 'single_user' THEN
        RETURN QUERY SELECT t.fcm_token FROM public.user_fcm_tokens t WHERE t.user_id = (p_target_filter->>'user_id')::UUID;
    -- Note: Expand these ELSIFs based on 'customers', 'technicians', 'service', and 'city' joins on specific local tables.
    ELSIF p_target_type = 'customers' THEN
        RETURN QUERY SELECT t.fcm_token FROM public.user_fcm_tokens t 
        JOIN public.user_roles ur ON t.user_id = ur.user_id 
        JOIN public.roles r ON ur.role_id = r.id
        WHERE r.name = 'client';
    ELSIF p_target_type = 'technicians' THEN
        RETURN QUERY SELECT t.fcm_token FROM public.user_fcm_tokens t 
        JOIN public.user_roles ur ON t.user_id = ur.user_id 
        JOIN public.roles r ON ur.role_id = r.id
        WHERE r.name = 'technician';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Enable pg_net for HTTP requests
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 7. Webhook Trigger to fire Edge Function
CREATE OR REPLACE FUNCTION public.trigger_campaign_edge_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when STATUS changes from anything to 'sending'
    IF (TG_OP = 'INSERT' AND NEW.status = 'sending') OR 
       (TG_OP = 'UPDATE' AND NEW.status = 'sending' AND OLD.status != 'sending') THEN
        PERFORM net.http_post(
            url := (SELECT value FROM (SELECT COALESCE(
                NULLIF(current_setting('app.settings.project_url', true), ''),
                'https://' || (NULLIF(current_setting('request.headers', true), '')::jsonb->>'host')
            ) as value) s) || '/functions/v1/admin-send-push',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || COALESCE(current_setting('app.settings.service_role_key', true), '')
            ),
            body := jsonb_build_object('record', row_to_json(NEW))
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_on_campaign_sending ON public.notification_campaigns;
CREATE TRIGGER tr_on_campaign_sending
    AFTER INSERT OR UPDATE ON public.notification_campaigns
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_campaign_edge_function();
