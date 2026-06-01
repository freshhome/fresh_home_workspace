# Workspace Rules (Fresh Home Project)

This document specifies the project-specific engineering rules, folder structures, database integrations, and development conventions for the **Fresh Home** platform.

---

## 1. Project Purpose & Scope

**Fresh Home** is a multi-platform service-on-demand monorepo designed to connect customers with specialized home services technicians. The platform includes three primary interfaces:
- **Customer App**: Used by clients to browse the service tree, build dynamic booking configurations, view real-time estimates, checkout, and track active bookings.
- **Staff (Technician) App**: Used by service technicians to manage their schedules, accept/reject assignments, update status, and report work completion.
- **Admin App**: Used by operational administrators to manage the service catalog, configure multi-stage pricing, build conditional AST rules, publish discount campaigns, and manually override bookings.

---

## 2. Architecture & Monorepo Structure

The project follows a modular **Clean Architecture** pattern in a monorepo setup:

```
d:\fresh_home_workspace/
├── apps/
│   ├── fresh_home_admin/       # Administration panel
│   ├── fresh_home_customer/    # Client application
│   └── fresh_home_staff/       # Technician application
├── packages/
│   ├── shared/                 # Core domain entities, mappers, DI setup, and common utilities
│   └── shared_features/        # Reusable features (Auth, Splash, Profile, Notifications)
└── supabase/
    ├── migrations/             # Numbered incremental SQL migration files
    ├── schema/                 # Base schema definitions (core, transactional, notifications)
    └── functions/              # Edge functions
```

### Monorepo Rules
- **Dependency Flow**: Apps depend on `packages/shared_features` and `packages/shared`. `packages/shared_features` depends on `packages/shared`.
- **Core Separation**: Custom application-specific logic lives inside the app's `lib/features/` folder. Reusable cross-app flows (like Auth and Splash) must live inside `packages/shared_features`.

---

## 3. State Management Conventions

- **State Library**: `flutter_bloc` using the **Cubit** pattern.
- **Data Flow**:
  1. UI widgets listen to `BlocBuilder` or trigger actions on a local `Cubit`.
  2. The `Cubit` invokes one or more Domain `UseCases` resolved via `GetIt`.
  3. The `UseCase` calls a `Repository` contract.
  4. The `Repository` implementation calls a `RemoteDataSource` (Supabase client) or `LocalDataSource` (Hive).
  5. The result returns back as an `Either<Failure, Success>`.
  6. The `Cubit` updates its state based on the result, triggering UI rebuilds.
- **No Repository in UI**: Widgets must never interact directly with repository classes. They must communicate exclusively via Cubits and UseCases.

---

## 4. Supabase Usage & Database Conventions

- **Data Sources Isolation**: The Supabase client (`SupabaseClient`) must only be called inside the data source files (`*remote_data_source.dart`).
- **Database Authority**: The PostgreSQL database is the final source of truth for pricing math, assignment selection, and booking state transitions.
- **Row Level Security (RLS)**: Enforce RLS policies on all tables, validating operations against user roles (`client`, `technician`, `admin`) via the authenticated JWT.
- **Remote Procedure Calls (RPCs)**: Use RPCs for transactional operations, security constraints, and math logic to avoid client-server drift. Key RPCs include:
  - `calculate_service_price`: Authoritative checkout pricing calculations.
  - `simulate_pricing_pipeline`: Sandboxed dry-runs for pricing configurations.
  - `transition_booking`: State machine lifecycle manager.
  - `get_available_technicians`: Dispatch checking slot bookings and availability.

---

## 5. Migration & Schema Workflow

- **Numbered Migrations**: All schema alterations must be added as incremental files in `supabase/migrations/` (e.g. `51_fix_check_constraint_null_fields.sql`). Never edit existing, applied migration files.
- **Schema Base Docs**: Keep SQL schema structures in `supabase/schema/` updated as reference files to easily understand the database's current state.

---

## 6. Storage Workflow

- **Images Bucket**: All icons and photos are stored in the public `service_images` bucket.
- **Asset Lifecycle**:
  - Image files uploaded during draft creation are placed in a temporary directory: `service_assets/temp/service_icons/...`.
  - When the configuration is saved/upserted, the system copies the asset to `service_assets/service_icons/<service_id>/...` and deletes the temporary file in the background.
- **RLS Buckets**: Reading assets is open to all users (`public`). Adding, updating, or deleting files is restricted to users with the `admin` role.

---

## 7. Naming & Coding Conventions

- **Layer Suffixes**:
  - UseCases must end with `UseCase` (e.g., `GetPricingRulesUseCase`).
  - Repositories contracts must end with `Repository` (e.g., `ServiceRepository`), and implementations must end with `RepositoryImpl`.
  - Cubits must end with `Cubit` (e.g., `PricingGovernanceCubit`).
- **Models vs Entities**: Classes under `data/models/` represent raw database payloads and contain `fromJson`/`toJson` serializers. Classes under `domain/entities/` represent clean business models and must extend `Equatable` to support value-equality checks.

---

## 8. Feature Development Workflow

When introducing a new feature module:
1. Define the Domain Entities and Repository contracts.
2. Build the Data Models and DataSource implementations, mapping raw payloads.
3. Write the UseCases to coordinate domain behavior.
4. Implement the Cubits and define states (`Initial`, `Loading`, `Loaded`, `Error`).
5. Write the UI Pages and Widgets, consuming the Cubit.
6. Register all classes in the Dependency Injection (DI) system (`injection_container.dart` / `*_di.dart`).
7. Append routes to the declaratively managed `GoRouter` configuration.

---

## 9. Verification & Testing

- **Testing Structure**: Place unit/integration tests under the `test/` directory mirroring the architecture path.
- **No Mock Assumptions**: Always ensure database migrations and triggers run correctly by running automated checks.

---

## 10. Documentation Rules

- **Feature Context**: Every feature must include a local `*_context.md` in its root folder explaining state logic and schemas.
- **Drift Auditing**: Document all client/server drift checks. If logic discrepancies arise between Dart code and SQL code, log a detailed issue in the next status report.
- **Unclear Behaviors**: If any feature code, database trigger, or logic transition is not fully verified, mark it explicitly: `"Needs manual verification."`
