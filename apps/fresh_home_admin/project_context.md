# Global Context (project_context.md)

## Project Overview
Fresh Home is a multi-platform service platform (Customer, Admin, Staff) built with Flutter and Supabase. It uses a monorepo structure with shared packages for core logic and reusable features.

## Tech Stack
- **Framework**: Flutter (SDK ^3.11.0)
- **Architecture**: Clean Architecture (Layers: Data, Domain, Presentation)
- **State Management**: Cubit (flutter_bloc)
- **Backend**: Supabase (Auth, DB, Real-time)
- **Navigation**: GoRouter
- **Dependency Injection**: GetIt
- **Functional Programming**: Fpdart (Either for error handling)

## Folder Structure
- `apps/`: Application-specific code (`fresh_home_admin`, `fresh_home_customer`, `fresh_home_staff`).
- `packages/shared/`: Core domain entities, generic repositories, and shared data models.
- `packages/shared_features/`: Reusable high-level features (Auth, Profile, User Management).

## Global Rules (CRITICAL)
- **No API/Supabase calls in UI**: All data logic must reside in Cubits/Repositories.
- **Strict Layer Separation**: Presentation depends on Domain; Data implements Domain.
- **Repository Pattern**: Business logic interacts with Repository interfaces, not implementations.
- **Real-time**: Use Streams (Supabase PostgREST) for live data updates.
- **Naming**: Follow clean code and suffixing (Cubit, State, RepositoryImpl, UseCase).

## Shared Patterns
- Use `Failure` class for error handling in Domain/Data.
- Use `Either<Failure, T>` from `fpdart` for return types.
- Manual DI via `GetIt` in `di/` folders.
