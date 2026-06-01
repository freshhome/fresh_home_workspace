# Services Context (services_context.md)

## Overview
Customer feature for browsing the available service catalog (Main Services and Sub Services) before starting a booking.

## Architecture
- **Cubit**: `ServicesCubit` manages the exploration state.

## Data Flow
UI (Category Grid/Service Details) → `ServicesCubit` → `GetServiceCatalogUseCase` → `ServiceRepository` → Supabase.

## Rules
- **Read-Only**: This feature is for browsing; configuration happens in the `booking` feature.
- **Visuals**: Primary entry point; must be visually rich and responsive.

## Existing Files
- `apps/fresh_home_customer/lib/features/services/presentation/cubit/services_cubit.dart`
