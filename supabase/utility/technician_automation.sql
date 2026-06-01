-- ==============================================================================
-- Fresh Home: Automated Technician Setup (Development Mode)
-- Description: Automatically configures new technicians for testing
-- ==============================================================================

-- 1. Create the automation function
CREATE OR REPLACE FUNCTION public.automate_technician_setup()
RETURNS TRIGGER AS $$
BEGIN
    -- A. Set default availability to TRUE for new technicians
    NEW.is_available := true;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the trigger on technician_profiles
DROP TRIGGER IF EXISTS trg_automate_tech_setup ON public.technician_profiles;
CREATE TRIGGER trg_automate_tech_setup
BEFORE INSERT ON public.technician_profiles
FOR EACH ROW
EXECUTE FUNCTION public.automate_technician_setup();

-- 3. Optional: Sync existing technicians right now to be sure
UPDATE public.technician_profiles SET is_available = true;
