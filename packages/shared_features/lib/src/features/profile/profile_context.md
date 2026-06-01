# Profile Context (profile_context.md)

## Overview
Shared feature for managing user profiles, specializing in nested entities like Multiple Phone Numbers and Multiple Addresses.

## Architecture
Clean Architecture.
- **Cubit**: `ProfileCubit` handles profile fetching and UPSERT operations.
- **Domain**: Entities for `User`, `Phone`, and `Address`.
- **Data**: Repository implementations for profile and sub-entities.

## Models
- **User**: Core profile data.
- **Phone**: ID, label (Home, Work, etc.), number, primary flag.
- **Address**: ID, coordinates, street, landmark, label.

## Data Flow
UI (Profile Settings) → `ProfileCubit` → `UpdateProfileUseCase` → `ProfileRepository` → Supabase Tables (`profiles`, `phones`, `addresses`).

## Rules
- **Atomic Operations**: Profile updates should handle sub-entities updates atomically when possible.
- **Validation**: Strict validation for phone formats and address coordinates.

## Existing Files
- `lib/src/features/profile/presentation/cubit/profile_cubit.dart`
- `packages/shared/lib/domain/user/entities/user/user.dart`
