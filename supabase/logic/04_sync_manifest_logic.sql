-- ==============================================================================
-- Fresh Home: Sync Manifest Logic (v3.0 - Unified Services Tree)
-- Description: Tracking changes for Offline-First synchronization
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.services_updated (
    id INT PRIMARY KEY DEFAULT 1,
    last_updated_at TIMESTAMPTZ DEFAULT NOW(),
    services JSONB DEFAULT '{}', -- service_id -> timestamp (tracks both leaf and category nodes)
    sub_services JSONB DEFAULT '{}', -- Deprecated/kept empty to avoid schema breaks on older client versions
    CONSTRAINT single_row CHECK (id = 1)
);

-- Initialize if empty
INSERT INTO public.services_updated (id) VALUES (1) ON CONFLICT DO NOTHING;

-- 1. TRIGGER TO UPDATE GLOBAL TIMESTAMP UNDER SERVICES KEY
CREATE OR REPLACE FUNCTION public.update_sync_manifest() RETURNS TRIGGER AS $$
BEGIN
    -- Updates the unified services manifest under the single key 'services'
    UPDATE public.services_updated 
    SET services = services || jsonb_build_object(NEW.id::TEXT, NOW()),
        last_updated_at = NOW()
    WHERE id = true;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 2. ASSIGN TRIGGERS
DROP TRIGGER IF EXISTS trg_main_services_sync ON public.main_services;
DROP TRIGGER IF EXISTS trg_sub_services_sync ON public.sub_services;

DROP TRIGGER IF EXISTS trg_services_sync ON public.services;
CREATE TRIGGER trg_services_sync 
AFTER INSERT OR UPDATE ON public.services 
FOR EACH ROW EXECUTE PROCEDURE public.update_sync_manifest();
