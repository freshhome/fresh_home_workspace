# Architecture Summary

This document describes the architectural patterns, code structures, data flows, and design decisions of the **Fresh Home** platform.

---

## 1. Clean Architecture & Monorepo Pattern

Fresh Home uses a monorepo structure. Within both shared packages and specific applications, code is organized around **Clean Architecture** boundaries to separate business logic from UI code and external dependencies:

```
                  ┌────────────────────────┐
                  │   Presentation Layer   │
                  │   (Widgets, Cubits)    │
                  └───────────┬────────────┘
                              │ (calls)
                              ▼
                  ┌────────────────────────┐
                  │      Domain Layer      │◄────────┐
                  │ (Entities, UseCases,   │         │
                  │  Repository Interfaces)│         │
                  └────────────────────────┘         │
                              ▲                      │ (implements)
                              │ (instantiates)       │
                  ┌───────────┴────────────┐         │
                  │       Data Layer       │─────────┘
                  │   (Models, Sources,    │
                  │     Repo Impls)        │
                  └────────────────────────┘
```

- **Domain Layer (Entities, UseCases, Repository Interfaces)**: 
  The core of the application. It contains the business rules and holds no dependencies on external frameworks, databases, or UI libraries. All external systems are represented as interface contracts (abstractions).
- **Data Layer (Models, Repositories Implementations, Data Sources)**: 
  Implements the repository contracts defined in the Domain layer. Data Sources interact directly with external systems like the Supabase client or local storage engines. Models extend domain entities, adding parsing logic (`fromJson`/`toJson`).
- **Presentation Layer (Pages, Custom Widgets, Cubits, States)**: 
  Consists of the visual interfaces and state managers. Cubits capture user input and trigger Domain UseCases.

---

## 2. Dependency Flow

The monorepo dependency hierarchy is structured as follows:

```
┌────────────────────────────────────────────────────────┐
│                   Applications (apps/)                 │
│  [fresh_home_admin]  [fresh_home_customer]  [fresh_home_staff] │
└───────────────────────────┬────────────────────────────┘
                            │ (depends on)
                            ▼
┌────────────────────────────────────────────────────────┐
│             packages/shared_features                   │
│   (Auth, Profile, Settings, Onboarding, Splash, etc.)  │
└───────────────────────────┬────────────────────────────┘
                            │ (depends on)
                            ▼
┌────────────────────────────────────────────────────────┐
│                   packages/shared                      │
│   (Core Domain, Base Models, DI container, Hive, etc.) │
└───────────────────────────┬────────────────────────────┘
                            │ (depends on)
                            ▼
┌────────────────────────────────────────────────────────┐
│              Third-Party Frameworks                    │
│      (Supabase SDK, Flutter, GetIt, Bloc, Hive)        │
└────────────────────────────────────────────────────────┘
```

- **DI Resolution**: Dependency Injection is managed centrally using **GetIt**. During app boot, `di.initAppDI()` is called, registering shared features and app-specific dependencies.
- **Routing**: Handled declaratively by **GoRouter**. The `AppRouterConfig` class collects shared feature routes alongside custom app routes, packaging them inside a single routing structure.

---

## 3. State Management & Data Flow

### A. State Lifecycle (Cubit)
1. **User Interaction**: The user performs an action in the UI (e.g., clicks "Save Pricing Rule").
2. **Cubit Call**: The widget calls a function on the corresponding `Cubit` (e.g., `_saveRule()` calls `PricingGovernanceCubit.savePricingRule`).
3. **State Transition**: The Cubit immediately emits a `Loading` state, triggering progress indicators in the UI.
4. **UseCase Invocation**: The Cubit triggers a Domain UseCase.
5. **Execution**: The UseCase coordinates domain objects and accesses repository contracts.
6. **Result Capture**: The repository implementation returns an `Either<Failure, Success>` object.
7. **Final State**: The Cubit receives the result. It emits a `Success` state (updating local fields) or an `Error` state (holding error metadata). The UI rebuilds to reflect the outcome.

### B. Structural Data Flow Diagram
```
[ UI Widget ] ──(triggers method)──► [ Cubit ]
      ▲                                   │
      │ (listens to states)               │ (invokes)
      │                                   ▼
[ UI State ] ◄──(emits update)────── [ UseCase ]
                                          │
                                          │ (calls contract)
                                          ▼
[ RemoteDataSource ] ◄─(executes)── [ RepositoryImpl ]
        │
        ├─► Supabase REST API (PostgREST)
        ├─► Supabase RPC Database Functions (PL/pgSQL)
        └─► Supabase Storage buckets
```

---

## 4. Supabase Integration Flow

- **Client Registration**: The `SupabaseClient` instance is initialized globally and registered as a lazy singleton in `GetIt` during the initialization of the shared layer (`supabase_di.dart`).
- **Data Serialization**: Remote data sources retrieve raw JSON maps from Supabase and pass them to model classes (like `ServiceRemoteModel`) which use `json_serializable` for strong typing. The models are then converted into domain entities.
- **Role Verification**: Auth logic uses the `EnsureRoleUseCase` to match the active user's role against the required application permission level, preventing unauthorized access.
- **Transactional Consistency**: Multi-table updates are executed using PostgreSQL Remote Procedure Calls (RPCs), ensuring operations succeed or fail atomically.

---

## 5. Important Design Decisions

### A. Server-Side Calculations
To prevent client-side security vulnerabilities and calculation discrepancies, all final price evaluations must be computed on the database level. Dart calculations are reserved for offline previews, and a drift warning card notifies users if local math differs from the server.

### B. Database-Level Transitions
All booking status changes must be processed through the `transition_booking` RPC. This enforces role-based access controls and guarantees that audit logs are written in the same transaction.

### C. Configuration Versioning
To protect historical records from schema modifications, the system saves the active pricing layout configuration to a version history table and links the booking to a version ID (`price_config_version_id`).
