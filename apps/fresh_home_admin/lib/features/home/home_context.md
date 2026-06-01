# Home Context (home_context.md)

## Overview
The structural backbone of the Fresh Home Admin app, providing the scaffold, top-level navigation, and shared layout components.

## Architecture
Uses a Shell routing approach with `GoRouter`.
- **Cubit**: `HomeCubit` (optional) to track UI state like selected tab.

## Data Flow
UI (HomePage) → Navigation Shell → Sub-routing to features (Dashboard, Users, Profile).

## Rules
- **No Business Logic**: Keep the Home feature purely structural.
- **Routing Integrity**: Ensure the shell correctly maintains state during feature transitions.

## Existing Files
- `apps/fresh_home_admin/lib/features/home/presentation/pages/home_page.dart`
