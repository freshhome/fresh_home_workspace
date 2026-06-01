# Authentication Context (authentication_context.md)

## Overview
Shared feature for user identity management, covering Sign In, Sign Up, Google OAuth, and Password Reset.

## Architecture
Clean Architecture. Shared logic across all apps.
- **Presentation**: `AuthCubit` manages the login/register flows and navigation.
- **Domain**: UseCases for each auth action (e.g., `SignInUseCase`, `VerifyRoleUseCase`).
- **Data**: `AuthRepositoryImpl` interacts with Supabase Auth.

## State Management
- **AuthCubit**: Orchestrates the authentication lifecycle and roles verification.
- **States**: `AuthInitial`, `AuthLoading`, `AuthError`, `SignInSuccess`, `SignUpSuccess`, `AuthPendingRoleState`.

## Models
- **UserRole**: Enum (admin, client, technician) used for app-level access control.
- **Credentials**: Email and Password objects for validation.

## Data Flow
UI (LoginView) → `AuthCubit` → `SignInUseCase` → `AuthRepository` → Supabase Auth.

## Rules
- **Role Verification**: Admin and Staff apps must verify the user's role post-login. Customer app (client) usually skips this if it's the default.
- **Naming**: Use `auth_` prefix for all authentication-related files.

## Existing Files
- `lib/src/features/authentication/presentation/cubit/auth_cubit.dart`
- `lib/src/features/authentication/domain/use_cases/sign_in_user.dart`
