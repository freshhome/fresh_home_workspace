# Technician Orders Context (technician_orders_context.md)

## Overview
Core feature for Staff/Technicians to view assigned tasks, update order status, and report completion.

## Architecture
- **Cubit**: `TechnicianOrdersCubit` tracks current and upcoming assignments.
- **Domain**: `OrderEntity`, `Assignment`.

## State Management
- **TechnicianOrdersCubit**: Manages the technician's queue and status transitions (Accept → On Way → Started → Completed).

## Data Flow
UI (Job Queue/Job Details) → Cubit → UseCase → OrderRepository → Supabase.

## Rules
- **Status Progression**: Enforce a strict state machine for order status.
- **Offline Readiness**: Consider caching and eventual synchronization for areas with poor connectivity.

## Existing Files
- `apps/fresh_home_staff/lib/features/technician_orders/presentation/cubit/technician_orders_cubit.dart`
