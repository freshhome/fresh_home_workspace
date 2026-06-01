# User Management Context (user_management_context.md)

## Overview
Admin feature for managing platform users, including Clients and Technicians. Supports role assignment and profile moderation.

## Architecture
- **Cubit**: `UserManagementCubit` (List view) and `UserDetailCubit` (Modification view).
- **Domain**: `UserEntity`, `Profile` (Client/Technician).

## Models
- **UserEntity**: id, email, role, status.
- **Profile**: name, addressIds, phoneIds.

## Data Flow
UI (User List/Details) → Cubit → UseCase → UserRepository → Supabase RPC/Tables.

## Backend
- Uses Supabase RPC for sensitive role updates.
- Real-time notification for user status changes.

## Rules
- **Admin Only**: Operations restricted by role; enforce checks in both UI and Cubits.
- **Audit**: Log sensitive changes (like role updates) when possible.

## Existing Files
- `apps/fresh_home_admin/lib/features/user_management/presentation/cubit/user_management_cubit.dart`
- `apps/fresh_home_admin/lib/features/user_management/presentation/cubit/user_detail_cubit.dart`
