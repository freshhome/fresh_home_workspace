# Current Status Report

This document outlines the current state of the **Fresh Home** platform, categorizing modules by completeness, identifying technical debt and risks, and detailing the next development steps.

---

## 1. Completed Modules

### A. Authentication & Session Security
- Supabase Authentication is fully integrated across all platforms.
- Role-based redirection is implemented, routing users to Customer, Staff, or Admin layouts based on roles.
- Safe route guards (`EnsureRoleUseCase`) prevent unauthorized login attempts.

### B. Navigation & Layout Foundation
- Unified shell routing is set up using GoRouter.
- Adaptive design configurations (`MainLayout`, responsive tables, theme cubits) are fully configured.

### C. Services & Shared Asset Management
- Unified sub-services structure is operational in the database.
- A shared icon system is implemented, tracking icon usage counts and running automatic cleaning tasks.

### D. Pricing MVP Simulation Bridge
- Deprecated legacy client-side calculations (`USE_LEGACY_PRICING = false`) to enforce server-side authority.
- The `PricingSimulationGateway` is integrated, querying the `simulate_pricing_pipeline` RPC on the server.
- Built a Drift Warning alert card, notifying users with a red card warning if client calculations differ from server values by more than 2%.

### E. Financial System Schema & Foundations (Phase 2)
- Created the complete database schema including custom enums, tables (`technician_financial_accounts`, `financial_adjustments`, `ledger_entries`, `settlement_requests`, `financial_cases`, `financial_case_events`).
- Enforced hard ledger immutability via `trg_prevent_ledger_modifications` preventing any `UPDATE` or `DELETE` commands.
- Established an automated status engine trigger to recalculate technician financial state (`active`, `restricted`, `blocked`) based on their debt-limit ratios.
- Configured indexes, storage buckets, and Row-Level Security (RLS) policies for all financial tables.
- Saved SQL definitions in `60_financial_system_schema.sql` (migrations) and `06_financial_system.sql` (schema).
- Published the comprehensive Financial System Design Hub under [docs/financial_system/](file:///d:/fresh_home_workspace/docs/financial_system/README.md).

---

## 2. Partially Completed Modules

### A. Pricing Governance Phase 2 UI
- The visual rule builder (`visual_rule_builder_page.dart`) compiles condition AST models correctly.
- The discount campaign page (`discount_campaign_builder_page.dart`) supports percentage/fixed rates and validity dates.
- *Status*: The UI templates are complete and write to the database. However, the parser logic for complex AST rules needs manual verification in real-world scenarios.

### B. Technician Daily Schedule & Capacity Limits
- View screens (`admin_daily_schedule_page.dart`, `admin_sub_service_capacity_page.dart`) are implemented in the Admin app.
- *Status*: Full synchronization between automated slot allocation and manual capacity updates needs manual verification.

---

## 3. Missing Modules

### A. Payment Integrations
- Online checkouts (Stripe/HyperPay) are planned but not yet implemented. All bookings currently default to cash-on-completion parameters.

### B. Technician Real-time GPS Tracking
- Live map coordination to show customer technician location updates is missing.

### C. Advanced Operations Analytics
- Heatmaps, peak-demand schedules, and PDF reporting tools are not yet implemented.

---

## 4. Technical Debt

- **Mathematical Duplication**: The pricing math rules are written in both Dart (for offline UI preview calculations) and SQL (for final invoice calculations). Although the drift warning card addresses this, it remains a maintenance risk.
- **Cache Invalidation**: Hive stores metadata structures locally but lacks an automated force-refresh protocol when admins change schemas.
- **Inconsistent Logging & Comments**: Code comments are mixed, using both English and Arabic (e.g. `// ! جلب كل الخدمات`). These comments should be standardized.

---

## 5. Potential Risks

- **AST Logic Loops**: Highly nested conditional AST configurations could cause slow PostgreSQL executions or performance issues.
- **Offline Sync Gaps**: If field staff lose connectivity, state transition requests may fail without an offline sync queue.

---

## 6. Suggested Next Development Phase

We recommend focusing the next development phase on **Phase 3 & Phase 4 of the Financial System**:
1. **Phase 3: Technician Financial App Integration**: Replace mock transactions in the technician app's `FinancialCubit` with live database calls to read accounts and ledger entries, and implement settlement request forms with proof uploads.
2. **Phase 4: Admin Financial Dashboard & Case Resolutions**: Develop pages in the admin app to approve/reject settlements, review manual adjustments, and resolve cash discrepancy cases.
3. **AST Parser Tests**: Write unit tests for the PostgreSQL PL/pgSQL AST parser (`evaluate_ast_condition`) to ensure robust evaluation of conditional logic.
