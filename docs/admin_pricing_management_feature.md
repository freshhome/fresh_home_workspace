# Fresh Home — Admin Pricing Management Architecture Plan
## Pre-Implementation Review & High-Fidelity Execution Blueprint

This document specifies the comprehensive architectural plan, feature gap analyses, user journey flows, and database mapping details for the **Admin Application Pricing Management Feature** of the Fresh Home platform.

---

## 1. Full Admin App Audit

### A. Current Structure & Components:
*   **State Management**: Features leverage Dart/Flutter `Cubit` (e.g. `admin_sub_services_cubit.dart`, `supabase_services_cubit.dart`) for state encapsulation and emission.
*   **UI Assets**: A powerful local layout editor `SubServicePriceConfigBuilderPage` is implemented. It enables dynamic fields metadata compilation and option add-ons composition, alongside a local client-side preview calculator.
*   **Infrastructure Layout**: Clean Architecture patterns are utilized within separate feature modules containing data models, domain repositories, usecases, and UI pages.

---

## 2. Feature Gap Analysis

| Current Admin App State | Required Enterprise Pricing State | Identified Gap & Remediation Action |
| :--- | :--- | :--- |
| **Local Calculator Preview**: Custom offline logic running inline math rules (`_calculateSimulatedBase()`). | **Authoritative Server Pipeline**: Simulation matching exact Stage 1-5 database rules. | **Simulation Gap**: Replace the local calculator with dynamic `simulate_pricing_pipeline` RPC queries to prevent client-server calculation drift. |
| **Fixed Pricing Configuration**: Basic pricing fields and layout modifiers. | **Relational Rules Engine**: AST rule tables (`pricing_rules`) with logical AND/OR groups. | **Visual Rule Builder Gap**: Build recursive UI nodes (`ConditionGroupWidget`) that compile back into condition JSONB syntax. |
| **Opaque Campaign Configurations**: No promotion builder or coupon tracker. | **Stackable Promotions Engine**: Stackable parameters, validity timelines, and usage count limits. | **Discount Campaigns Builder Gap**: Introduce first-class visual forms managing `pricing_discounts` tables. |
| **Opaque Transaction History**: Bookings contain static totals snapshots without details. | **Locked Snapshots & Time-Travel**: Lockups tied to versions (`pricing_version_id`) and audit logs. | **Audit Trail Gap**: Integrate versions history viewer and sandboxed replay auditing triggers. |

---

## 3. Proposed Feature Architecture (Clean Architecture)

We specify the exact directory structures for the new pricing module to align with clean design rules:

```
lib/features/pricing_governance/
├── data/
│   ├── data_sources/
│   │   └── pricing_governance_remote_data_source.dart (Supabase RPC adapter)
│   ├── models/
│   │   ├── pricing_rule_model.dart
│   │   ├── pricing_discount_model.dart
│   │   └── pricing_version_model.dart
│   └── repositories_impl/
│       └── pricing_governance_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── pricing_rule_entity.dart
│   │   ├── pricing_discount_entity.dart
│   │   └── pricing_version_entity.dart
│   ├── repositories/
│   │   └── pricing_governance_repository.dart
│   └── use_cases/
│       ├── simulate_pricing_pipeline_usecase.dart
│       ├── get_pricing_versions_usecase.dart
│       ├── get_governance_audit_logs_usecase.dart
│       └── replay_booking_pricing_usecase.dart
└── presentation/
    ├── cubit/
    │   ├── pricing_governance_cubit.dart
    │   └── pricing_governance_state.dart
    └── pages/
        ├── pricing_governance_dashboard.dart
        ├── visual_rule_builder_page.dart (AST tree builder)
        ├── discount_campaign_builder_page.dart (Promotional options form)
        ├── pricing_simulation_sandbox_page.dart (Stage 1-5 sandboxed comparison panel)
        └── pricing_version_history_page.dart (Replays audit comparison log)
```

### Dynamic Sandbox Data Flow:
```
  [ Visual UI Widgets ] (Toggles, sliders, AST nested conditions)
           │
           ▼ (dart compileAst compiler)
  [ Proposed Configuration Payload ] (JSONB config + Rules + Discounts + Test inputs)
           │
           ▼ (simulate_pricing_pipeline RPC)
  [ Supabase Simulator RPC ] (Sandbox execution, no side-effects)
           │
           ▼ (Stage 1-5 Context Contract returned)
  [ UI Comparison Dashboard ] (Displays original vs replayed simulation values)
```

---

## 4. Admin User Journeys

### A. Modifying a Service Price:
1.  Admin navigates to **Services Management**, taps a sub-service, and chooses **Pricing Config**.
2.  Taps **Tuning**, edits base prices or adds layout toggles.
3.  Tapes **Simulation Sandbox** tab to inspect pipeline changes using test values before saving.
4.  Applies changes: compiles a new version snapshot, writes a `pricing_governance_audit` log, and updates the live service config.

### B. Composing an AST Relational Rule:
1.  Admin opens **Visual Rule Builder**, taps **Add Rule**.
2.  Renders recursive `ConditionGroupWidget`. Admin adds logical conditions:
    *   `[ AND ]` group:
        *   `area > 150`
        *   `furnished == true`
3.  Defines the action target: `[ Multiply subtotal by 1.15 ]` (e.g. Luxury Surcharge).
4.  Compiler compiles tree into standard AST JSON. Admin simulated the rule, reviews stage impacts, and saves safely.

---

## 5. Safety & Consistency Verification

*   **Double AST Validator**: The app validates AST integrity locally. If it passes, the database `public.validate_condition_ast` check constraint provides a second authoritative verification block before writing.
*   **30% Discount Boundary Guard**: The admin dashboard validates fixed/percentage promos. It pops a warning if combined simulation values exceed the 30% pipeline capping rules.
*   **Zero-Downtime Rollouts**: Because version capture compiles active snapshots on-the-fly, existing/legacy bookings continue to reference historical versions without recalculation errors.

---

## 6. Implementation Strategy

### Recommended UI Screens:
1.  **Pricing Governance Dashboard**: Base service rate overviews, active promos timelines, and audit logs.
2.  **AST Visual Rule Editor**: Logical grouping selectors (AND/OR nested blocks) for rules.
3.  **Discount Campaigns Manager**: stackable switches, priority sliders, date selectors, and coupon limit metrics.
4.  **Sandbox Simulator Panel**: Side-by-side comparison cards displaying before/after calculations and detailed trace paths.

### Risk Analysis & Mitigation:

| Identified Technical Risk | Potential Impact | Audited Mitigation Plan |
| :--- | :--- | :--- |
| **Logic Divergence**: Client app calculates math locally using custom formula fallbacks. | Discrepancy between preview prices shown to admin and live checkout totals. | **Mandatory server-side simulation**: Deprecate all custom Dart calculations. All previews must query the `simulate_pricing_pipeline` RPC. |
| **AST Corruption**: Poorly formatted logical blocks sent to Supabase. | Database writes fail due to constraint violations. | **Defensive local compilers**: Ensure that AST Dart models enforce non-empty operands and default valid condition structures. |

### MVP vs Full Version Rollout:
*   **Phase 1 (MVP)**:
    1.  Deploy remote datasources and Cubit bindings.
    2.  Implement the Sandbox Simulation Panel (replacing local math calculations with direct RPC queries).
    3.  Create simple discounts campaigns list manager (fixed/percentage toggles).
*   **Phase 2 (Full Version)**:
    1.  Introduce nested logical visual rule builders (AST builders).
    2.  Implement audit logs and time-travel replay viewers.
