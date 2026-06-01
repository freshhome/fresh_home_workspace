-- ==============================================================================
-- Fresh Home: Transactional Schema (v2.5)
-- Description: Bookings and Technician Service Mappings
-- ==============================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status_v2') THEN
        CREATE TYPE order_status_v2 AS ENUM (
            'created',
            'assigned',
            'accepted',
            'on_the_way',
            'arrived',
            'in_progress',
            'completed',
            'cancelled',
            'cancelled_by_customer',
            'cancelled_by_admin',
            'cancelled_by_technician',
            'failed_no_show',
            'expired'
        );
    END IF;
END $$;

-- 1. TECHNICIAN SERVICES (The mapping between tech and sub-service)
CREATE TABLE IF NOT EXISTS public.technician_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID NOT NULL REFERENCES public.technician_profiles(user_id) ON DELETE CASCADE,
    sub_service_id UUID NOT NULL REFERENCES public.sub_services(id) ON DELETE CASCADE,
    capacity_per_day INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(technician_id, sub_service_id)
);

CREATE INDEX IF NOT EXISTS idx_technician_services_tech_id ON public.technician_services(technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_services_sub_service_id ON public.technician_services(sub_service_id);

-- 2. BOOKINGS
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    readable_id TEXT UNIQUE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    service_id UUID REFERENCES public.sub_services(id),
    address_id UUID REFERENCES public.user_addresses(id),
    
    -- Snapshots
    address_snapshot JSONB NOT NULL,
    service_snapshot JSONB NOT NULL,
    price_snapshot JSONB NOT NULL,
    
    status order_status_v2 DEFAULT 'created',
    scheduled_day DATE NOT NULL,
    start_time_slot TIME DEFAULT '09:00',
    
    -- Professional Lifecycle Tracking
    assigned_at   TIMESTAMPTZ,
    accepted_at   TIMESTAMPTZ,
    dispatched_at TIMESTAMPTZ, -- 'on_the_way'
    arrived_at    TIMESTAMPTZ,
    started_at    TIMESTAMPTZ, -- 'in_progress'
    completed_at  TIMESTAMPTZ,
    cancelled_at  TIMESTAMPTZ,
    
    -- Cancellation Metadata
    cancellation_reason_code TEXT,
    cancelled_by_role        TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_scheduled_day ON public.bookings(scheduled_day);

-- 3. BOOKING EVENTS (Audit Trail)
CREATE TABLE IF NOT EXISTS public.booking_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    event_type  TEXT NOT NULL,
    actor_id    UUID,
    actor_role  TEXT,
    metadata    JSONB DEFAULT '{}'::JSONB,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_booking_events_lookup ON public.booking_events(booking_id, created_at DESC);
