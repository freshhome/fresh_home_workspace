# Services Management Context (services_management_context.md)

## Overview
Primary administrative interface for configuring the service catalog, covering Main Services and Sub Services management.

## Architecture
- **Presentation**: `ServicesManagementCubit` (Main Services) and `AdminSubServicesCubit` (Sub Services).
- **Domain**: Shared service domain entities and use cases.
- **Data**: Repository implementations with Supabase remote data sources.

## State Management
- **ServicesManagementCubit**: Fetches and manages the list of main services.
- **AdminSubServicesCubit**: Manages sub-service configuration, including a detailed editor for service specifics like requirements and pricing.

## Models
- **MainServiceEntity**: name, icon, description, isActive.
- **SubServiceEntity**: parentServiceId, title, basePrice, detailedInfo.

## Data Flow
UI (Service List/Form) → Cubit → UseCase → ServiceRepository → Supabase.

## Backend
- Real-time streams for the dashboard to reflect changes made by other admins.
- Uses storage for high-quality service imagery.

## Rules
- **Layer Separation**: No direct access to Supabase from the UI.
- **Validation**: Strict price and description validation for sub-services.

## Existing Files
- `apps/fresh_home_admin/lib/features/services_management/presentation/pages/services_management_page.dart`
- `apps/fresh_home_admin/lib/features/services_management/presentation/cubit/services_management_cubit.dart`
