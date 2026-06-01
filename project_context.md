# Global Context (project_context.md)

## Project Overview
Fresh Home is a multi-platform service platform (Customer, Admin, Staff) built with Flutter and Supabase. The project uses a monorepo architecture to share business logic, domain entities, and common features across the different applications.

## Tech Stack
- **Framework**: Flutter (SDK ^3.11.0)
- **Architecture**: Clean Architecture (Layers: Data, Domain, Presentation)
- **State Management**: Cubit (flutter_bloc)
- **Backend**: Supabase (Authentication, PostgreSQL Database, Storage, Edge Functions)
- **Navigation**: GoRouter (declarative routing)
- **Dependency Injection**: GetIt (centralized service locator)
- **Functional Programming**: Fpdart (Either for error handling and side effects)

## Folder Structure
- `apps/`: Application-specific code.
    - `fresh_home_admin`: Dashboard for fleet/service management.
    - `fresh_home_customer`: Client-facing app for bookings and orders.
    - `fresh_home_staff`: App for technicians to manage their assignments.
- `packages/shared/`: Core domain entities, generic repositories, utility functions, and shared data models.
- `packages/shared_features/`: Reusable high-level features (Auth, Profile, Onboarding).

## Global Rules
- **Layer Integrity**: Presentation depends only on Domain; Data implements Domain interfaces.
- **No Direct API Calls**: UI must interact with Cubits; Cubits must interact with UseCases or Repositories.
- **Repository Pattern**: Business logic interacts with Repository abstractions, ensuring data source independence.
- **Failures**: Use the `Failure` class system within `Either` for consistent error handling.
- **Real-time**: Leverages Supabase PostgREST streams for live data updates where necessary.
