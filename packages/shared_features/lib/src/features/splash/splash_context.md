# Splash Context (splash_context.md)

## Overview
Shared feature for app initialization, handling initial authentication checks and routing to the appropriate feature (Onboarding, Login, or Home).

## Architecture
- **Cubit**: `SplashCubit` manages the initialization logic.

## State Management
Decides the initial route based on authentication state and persistent flags (e.g., onboarding completion).

## Data Flow
UI (Splash Screen) → `SplashCubit` → `AuthCubit` (Check status) → GoRouter (Navigate).

## Rules
- Keep the splash screen visual and lightweight.
- Ensure initialization logic is fast and handles network failures gracefully.
