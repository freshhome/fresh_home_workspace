-- ==============================================================================
-- Fresh Home: Create Shared Icons Table & Policies
-- Migration ID: 39_create_shared_icons_table
-- ==============================================================================

-- 1. Create shared_icons table
CREATE TABLE IF NOT EXISTS public.shared_icons (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         JSONB NOT NULL,                  -- Multilingual name: {"ar": "...", "en": "..."}
    storage_path TEXT UNIQUE NOT NULL,            -- Path inside storage bucket (e.g. service_assets/shared_icons/uuid.webp)
    public_url   TEXT NOT NULL,                   -- Public HTTP URL for backward compatibility
    category     TEXT NOT NULL DEFAULT 'general', -- Category: rooms, tools, appliances, general
    usage_count  INT NOT NULL DEFAULT 0,          -- Track number of active references in services
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_shared_icons_category ON public.shared_icons(category);
CREATE INDEX IF NOT EXISTS idx_shared_icons_usage_count ON public.shared_icons(usage_count);

-- 2. RLS Policies for shared_icons table
ALTER TABLE public.shared_icons ENABLE ROW LEVEL SECURITY;

-- A. Anyone can view shared icons
DROP POLICY IF EXISTS "Anyone can view shared icons" ON public.shared_icons;
CREATE POLICY "Anyone can view shared icons"
ON public.shared_icons FOR SELECT
USING (true);

-- B. Admins can manage shared icons (Insert, Update, Delete)
DROP POLICY IF EXISTS "Admins can manage shared icons" ON public.shared_icons;
CREATE POLICY "Admins can manage shared icons"
ON public.shared_icons FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid() AND r.name = 'admin'
    )
);

-- 3. RPC Functions for atomic usage tracking updates
CREATE OR REPLACE FUNCTION public.increment_shared_icon_usage(p_icon_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.shared_icons
    SET usage_count = usage_count + 1
    WHERE id = p_icon_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.decrement_shared_icon_usage(p_icon_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.shared_icons
    SET usage_count = GREATEST(0, usage_count - 1)
    WHERE id = p_icon_id;
END;
$$ LANGUAGE plpgsql;
