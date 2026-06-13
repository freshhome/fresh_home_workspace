-- ==============================================================================
-- Fresh Home: Financial Analytics Engine & Storage Performance (Phase 8)
-- File: 69_create_financial_analytics_materialized_view.sql
-- Description: Creates the materialized view mv_monthly_financial_summary for monthly 
--              financial metrics aggregates, adds unique indexing for concurrent refreshing,
--              and registers a secure DEFINER RPC refresh_financial_reports().
-- ==============================================================================

BEGIN;

-- ── 1. CREATE MATERIALIZED VIEW ──────────────────────────────────────────────
DROP MATERIALIZED VIEW IF EXISTS public.mv_monthly_financial_summary CASCADE;

CREATE MATERIALIZED VIEW public.mv_monthly_financial_summary AS
WITH months AS (
    SELECT DISTINCT to_char(completed_at, 'YYYY-MM') AS month_year, date_trunc('month', completed_at)::date AS start_of_month
    FROM public.bookings
    WHERE status = 'completed'
    UNION
    SELECT DISTINCT to_char(reviewed_at, 'YYYY-MM') AS month_year, date_trunc('month', reviewed_at)::date AS start_of_month
    FROM public.settlement_requests
    WHERE status = 'approved'
)
SELECT
    m.month_year,
    m.start_of_month,
    -- Total Company Net Profit (Platform commission of all completed bookings)
    COALESCE((
        SELECT SUM(COALESCE((b.price_snapshot -> 'metadata' ->> 'platform_commission')::NUMERIC, 0.00))
        FROM public.bookings b
        WHERE b.status = 'completed'
          AND to_char(b.completed_at, 'YYYY-MM') = m.month_year
    ), 0.00) AS total_company_net_profit,
    -- Total Commissions (Same as platform commission)
    COALESCE((
        SELECT SUM(COALESCE((b.price_snapshot -> 'metadata' ->> 'platform_commission')::NUMERIC, 0.00))
        FROM public.bookings b
        WHERE b.status = 'completed'
          AND to_char(b.completed_at, 'YYYY-MM') = m.month_year
    ), 0.00) AS total_commissions,
    -- Total Cash Collected (Revenue collected by tech in cash)
    COALESCE((
        SELECT SUM((b.price_snapshot ->> 'total')::NUMERIC)
        FROM public.bookings b
        WHERE b.status = 'completed'
          AND COALESCE(b.payment_method, 'cash') = 'cash'
          AND to_char(b.completed_at, 'YYYY-MM') = m.month_year
    ), 0.00) AS total_cash_collected,
    -- Total Online Earnings (Revenue collected directly online)
    COALESCE((
        SELECT SUM((b.price_snapshot ->> 'total')::NUMERIC)
        FROM public.bookings b
        WHERE b.status = 'completed'
          AND COALESCE(b.payment_method, 'cash') != 'cash'
          AND to_char(b.completed_at, 'YYYY-MM') = m.month_year
    ), 0.00) AS total_online_earnings,
    -- Total Settlements Approved (Withdrawals & payouts approved)
    COALESCE((
        SELECT SUM(sr.amount)
        FROM public.settlement_requests sr
        WHERE sr.status = 'approved'
          AND to_char(sr.reviewed_at, 'YYYY-MM') = m.month_year
    ), 0.00) AS total_settlements_approved
FROM months m
ORDER BY m.month_year DESC;

-- ── 2. CREATE UNIQUE INDEX FOR CONCURRENT REFRESH ───────────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_financial_summary_month_year 
ON public.mv_monthly_financial_summary(month_year);

-- ── 3. CREATE CONCURRENT REFRESH PL/pgSQL FUNCTION ─────────────────────────
CREATE OR REPLACE FUNCTION public.refresh_financial_reports()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_monthly_financial_summary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant EXECUTE permission to authenticated role
GRANT EXECUTE ON FUNCTION public.refresh_financial_reports() TO authenticated;

COMMIT;
