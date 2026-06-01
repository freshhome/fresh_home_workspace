# Supabase Context (supabase_context.md)

## Overview
Supabase serves as the core backend infrastructure, providing Auth, Database, Storage, and Real-time capabilities.

## Key Services & Integration
- **Authentication**: Email/Password and Google OAuth. Managed via `Supabase.instance.client.auth`.
- **Database**: PostgreSQL with PostgREST for auto-generated REST APIs. Managed via `Supabase.instance.client.from()`.
- **Storage**: Used for assets like service icons and user avatars. 
- **Real-time**: Uses PostgreSQL Pub/Sub streams for live status updates (e.g., booking status, technician location).

## Common Patterns
- **DataSources**: Remote data sources interact directly with the Supabase client.
- **RLS (Row Level Security)**: Data access is secured at the database level based on the JWT role (admin, client, technician).
- **RPC (Remote Procedure Calls)**: Used for complex administrative operations that require elevated privileges or atomic multi-table updates.

## Rules
- Avoid including Supabase-specific logic in the domain layer.
- Ensure all remote data sources handle Supabase exceptions and map them to domain `Failure` types.
