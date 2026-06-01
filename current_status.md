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

We recommend focusing the next development phase on completing **Pricing Governance Phase 2**:
1. **Pipeline Constraints & Security Checks**: Implement automated tests for the 30% discount cap logic inside Stage 4.
2. **Version Comparison Tools**: Build a UI tool to compare active price configurations with previous version snapshots.
3. **AST Parser Tests**: Write unit tests for the PostgreSQL PL/pgSQL AST parser (`evaluate_ast_condition`) to ensure robust evaluation of conditional logic.
