-- ==============================================================================
-- Fresh Home: Performance Optimization (v1.0)
-- Description: Core indexes to ensure fast query performance as data grows.
-- ==============================================================================

-- 1. Bookings Search Optimization
-- Critical for: Admin List, Technician Orders, and SLA Monitor
CREATE INDEX IF NOT EXISTS idx_bookings_status_scheduled ON public.bookings(status, scheduled_day);
CREATE INDEX IF NOT EXISTS idx_bookings_technician_active ON public.bookings(technician_id, status) WHERE status NOT IN ('completed', 'cancelled', 'failed');
CREATE INDEX IF NOT EXISTS idx_bookings_critical ON public.bookings(is_critical) WHERE is_critical = TRUE;

-- 2. Notification Outbox Optimization
-- Critical for: Background Worker polling
CREATE INDEX IF NOT EXISTS idx_notifications_outbox_processing ON public.notifications_outbox(status, retry_count) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_notifications_outbox_created_at ON public.notifications_outbox(created_at);

-- 3. Audit & Events Performance
-- Critical for: Timeline rendering and history tracking
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id ON public.booking_events(booking_id, created_at DESC);

-- 4. Capacity & Availability Optimization
-- Critical for: Calendar loading and technician assignment
CREATE INDEX IF NOT EXISTS idx_technician_skills_service ON public.technician_skills(sub_service_id, is_active);
CREATE INDEX IF NOT EXISTS idx_capacity_overrides_date ON public.capacity_overrides(override_date, pool_id);

COMMENT ON INDEX public.idx_bookings_status_scheduled IS 'Ensures fast filtering of orders by day and lifecycle state.';
COMMENT ON INDEX public.idx_bookings_critical IS 'Allows the Emergency Queue to load instantly even with millions of records.';
