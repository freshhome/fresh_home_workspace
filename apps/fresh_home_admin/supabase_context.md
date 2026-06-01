# Supabase Context (supabase_context.md)

## Role
Core infrastructure providing Authentication, PostgreSQL Database, and Real-time data streams.

## Key Services
- **Auth**: Email/Password and Google OAuth. Managed via `Supabase.instance.client.auth`.
- **Database**: PostgreSQL with PostgREST. Interacted via `supabase_flutter`.
- **Real-time**: Leverages Supabase Channels and PostgreSQL periodic streams.

## Access Patterns
- **DataSources**: Direct interaction with the Supabase client.
- **Initialization**: Centralized in `SupabaseServices` feature (Admin App core infrastructure).
- **Queries**: Primarily done through repository implementations returning `Either` or `Stream`.

## Backend Rules
- Do not expose Supabase Client to UI.
- Use Repository pattern to wrap data fetching.
- Handle RLS (Row Level Security) on the backend; the app assumes scoped access based on `UserRole`.
