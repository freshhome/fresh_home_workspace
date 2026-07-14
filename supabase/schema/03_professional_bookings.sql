-- ==============================================================================
-- Fresh Home: Professional Booking Logic (v2.5)
-- Description: Automated Readable IDs and Professional Lifecycle Schema
-- ==============================================================================

-- 1. BOOKING SEQUENCE (Starting from 100000 for 6-digit feel)
CREATE SEQUENCE IF NOT EXISTS public.booking_number_seq START 100001;

-- 2. RE-MODERNIZED BOOKINGS TABLE
-- Note: We use DROP and RECREATE only for fresh installs. 
-- In a running system, migrations are used.
DROP TABLE IF EXISTS public.booking_events CASCADE;
DROP TABLE IF EXISTS public.bookings CASCADE;

CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    readable_id TEXT UNIQUE, -- Format: FH-O-100001
    
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    service_id UUID NOT NULL REFERENCES public.sub_services(id),
    address_id UUID REFERENCES public.user_addresses(id),
    
    -- Contact Information (If different from default)
    contact_name TEXT,
    contact_phones TEXT[],
    
    -- Snapshots
    address_snapshot JSONB NOT NULL,
    service_snapshot JSONB NOT NULL,
    price_snapshot JSONB NOT NULL,
    
    status order_status_v2 DEFAULT 'created',
    scheduled_day DATE NOT NULL,
    start_time_slot TIME DEFAULT '09:00',
    
    -- Reminders & Confirmations
    last_reminder_at TIMESTAMPTZ,
    is_confirmed_today BOOLEAN DEFAULT false,
    confirmed_today_at TIMESTAMPTZ,
    
    -- Professional Lifecycle Tracking
    assigned_at   TIMESTAMPTZ,
    accepted_at   TIMESTAMPTZ,
    dispatched_at TIMESTAMPTZ,
    on_the_way_at TIMESTAMPTZ,
    arrived_at    TIMESTAMPTZ,
    started_at    TIMESTAMPTZ,
    completed_at  TIMESTAMPTZ,
    cancelled_at  TIMESTAMPTZ,
    
    -- Cancellation Metadata
    cancellation_reason_code TEXT,
    cancelled_by_role        TEXT,
    
    -- Enhancements (Notes & Payment)
    customer_notes TEXT,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'pending',

    -- SLA & Emergency Tracking (New Feature)
    is_critical BOOLEAN DEFAULT false,
    critical_reason TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. AUTOMATED ID GENERATION TRIGGER
CREATE OR REPLACE FUNCTION public.fn_generate_booking_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.readable_id IS NULL THEN
        NEW.readable_id := 'FH-O-' || nextval('public.booking_number_seq')::TEXT;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_booking_id
BEFORE INSERT ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.fn_generate_booking_id();

-- 4. EVENTS TABLE (Professional Audit Trail)
CREATE TABLE public.booking_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    event_type  TEXT NOT NULL,
    actor_id    UUID REFERENCES public.profiles(id),
    actor_role  TEXT,
    metadata    JSONB DEFAULT '{}'::JSONB,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 5. UPDATED AT TRIGGERS
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- 6. INDEXES
CREATE INDEX idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX idx_bookings_readable_id ON public.bookings(readable_id);
CREATE INDEX idx_bookings_tech_id ON public.bookings(technician_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);
CREATE INDEX idx_bookings_scheduled_day ON public.bookings(scheduled_day);
