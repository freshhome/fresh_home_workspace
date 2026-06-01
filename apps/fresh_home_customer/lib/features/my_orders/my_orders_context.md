# My Orders Context (my_orders_context.md)

## Overview
Customer feature for tracking order history, checking current order status, and performing post-order actions (e.g., editing active orders).

## Architecture
- **Cubit**: `MyOrdersCubit` (List view) and `EditOrderCubit` (Modification).
- **Domain**: `OrderEntity`, `BookingEntity`.

## State Management
- **MyOrdersCubit**: Fetches and filters the user's past and active orders.
- **EditOrderCubit**: Handles specific updates to an existing order (if allowed).

## Data Flow
UI (Order List/Details) → Cubit → UseCase → OrderRepository → Supabase.

## Rules
- **Access Control**: Users MUST only see their own orders (enforced by RLS and client-side filtering).
- **Real-time Status**: Reflect technician progress (assigned, on the way, working, completed) in real-time.

## Existing Files
- `apps/fresh_home_customer/lib/features/my_orders/presentation/cubit/my_orders_cubit.dart`
