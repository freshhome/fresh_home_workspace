# Project Overview (Fresh Home)

This document provides a high-level overview of the **Fresh Home** platform, its applications, business modules, technology stack, and current development progress.

---

## 1. Project Purpose

**Fresh Home** is a professional on-demand services platform designed to connect customers with skilled, verified technicians (for services such as cleaning, maintenance, and home repairs). The system coordinates client requests, manages available staff resources, determines pricing dynamically on the database level, sends notifications, and provides operational oversight for administrators.

---

## 2. Applications in the Workspace

The workspace is organized as a monorepo containing three applications and two support packages:

- **`fresh_home_admin` (Admin App)**: 
  A desktop-focused web/tablet dashboard allowing operations managers to build services, edit metadata fields, set pricing rules, simulate discount campaigns, inspect live bookings, override scheduling conflicts, and view detailed audit logs.
- **`fresh_home_customer` (Customer App)**: 
  A mobile client application designed for home users to search for services, configure requirements, view real-time estimates, schedule bookings, make payments (planned), and track technician arrival in real-time.
- **`fresh_home_staff` (Staff/Technician App)**: 
  A mobile application designed for field technicians to view their daily schedule, accept or decline assignments, navigate to client locations, update job progress stages, and review their history.
- **`packages/shared`**: 
  A core package containing domain entities (User, Service, Booking), shared data mappers, repository interfaces, localized assets, global themes, and local storage configurations.
- **`packages/shared_features`**: 
  A package containing reusable feature workflows shared across multiple applications (e.g., Auth, Profile Details, App Settings, Splash Screen, Notification History).

---

## 3. Main Business Modules

### A. Authentication & Role Verification
- Utilizes Supabase Auth (Email/Password & Google OAuth).
- Custom role mapping table (`user_roles`) bridges base profiles with structural application permissions (`client`, `technician`, `admin`).
- Safe routing boundaries are maintained by verifying roles via `EnsureRoleUseCase` on initialization.

### B. Service Catalog & Metadata Configuration
- Hierarchical service tree representing Main Services (parent categories) and Sub Services (specific bookable jobs).
- Sub-services support a flexible layout schema (`price_config` stored as a JSONB object), which contains UI display configurations, layout modifiers, validation limits, options groups, and formulas.

### C. Smart Assignment & Dispatching Engine
- Automatically assigns bookings to technicians based on specialized skills, service areas, slot availability, and capacity limits.
- Balances technician work volumes using active load monitoring.
- Provides admin-controlled overrides to resolve scheduling conflicts manually.

### D. Booking State Machine & Auditing
- A strict database-level transition engine (`transition_booking` RPC) controls the order lifecycle:
  `created` → `assigned` → `accepted` → `on_the_way` → `arrived` → `in_progress` → `completed`/`cancelled`.
- Every phase transition generates immutable audit entries in `booking_events` and logs.

### E. Multi-Stage Pricing Pipeline & Pricing Governance
- Authoritative server-side pricing engine operating in 5 isolated stages:
  1. **Stage 1 (Base Pricing)**: Calculates base rates multiplied by user input dimensions.
  2. **Stage 2 (Conditional Modifiers)**: Evaluates complex AST rules against input parameters.
  3. **Stage 3 (Options/Add-ons)**: Adds selected user options to the subtotal.
  4. **Stage 4 (Discount & Coupon Pipeline)**: Applies stackable promotions and enforces a global 30% discount cap.
  5. **Stage 5 (Final Aggregation)**: Aggregates VAT, sub-service minimum order prices, and final totals.
- Administrative tools include a visual AST conditions builder, discount campaign publishers, a sandbox simulator running direct RPC queries, and version history.

---

## 4. Technology Stack

- **Mobile/Client Framework**: Flutter (SDK ^3.11.0)
- **Backend & Cloud Infrastructure**: Supabase
  - **Database**: PostgreSQL (v15+)
  - **Auth**: Supabase Go-JWT-based system
  - **Storage**: Supabase Storage buckets (S3 compatible)
  - **Real-Time**: PostgREST pub/sub streams for live scheduling updates
  - **RPCs / Store Procedures**: PL/pgSQL database functions
- **Push Notification System**: Firebase Cloud Messaging (FCM) + Supabase triggers
- **State Management**: BLoC / Cubit (`flutter_bloc`)
- **Navigation**: GoRouter (declarative routing)
- **Dependency Injection**: GetIt
- **Local Storage**: Hive (caching credentials, themes, and locale data)
- **Functional Programming Helpers**: `fpdart` (Either/Failure models)

---

## 5. Current Development Status

- **Core Framework & DI**: Complete. Centralized navigation router configurations and DI containers are fully operational.
- **Authentication**: Complete. Supabase Auth, Google Sign-in redirect rules, and client role enforcement (`EnsureRoleUseCase`) are fully implemented.
- **Service Catalog**: Complete. Database schemas, dynamic configurations, and shared icon usage counting are fully set up.
- **Booking Flow**: Complete. Lifecycle state machine, RLS policies, PostgreSQL transitions, and timeline builders are implemented.
- **Pricing MVP Bridge**: Complete. Deprecated legacy client-side calculations (`USE_LEGACY_PRICING = false`) and implemented the live cloud sandbox connector (`PricingSimulationGateway`) to avoid arithmetic drifts.
- **Pricing Governance UI (Admin)**: Complete. Includes visual rule AST builder, discount campaign management, Sandbox Simulator, and Version history page.
