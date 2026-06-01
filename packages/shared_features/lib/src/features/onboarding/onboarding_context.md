# Onboarding Context (onboarding_context.md)

## Overview
Shared feature managing the initial user experience for new installations, introducing the app value and guiding to authentication.

## Architecture
Simple presentation-driven flow.
- **Cubit**: `OnboardingCubit` tracks the current page and completion status.

## State Management
Persistent flag in local storage to skip onboarding once completed.

## Data Flow
UI (Onboarding Screen) → `OnboardingCubit` → Local Storage (Shared Preferences).

## Rules
- Keep visuals stunning and micro-animations subtle.
- Should be the first screen for unauthenticated users on first launch.
