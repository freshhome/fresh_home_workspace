# Deep Technical Audit: Services Architecture & Data Flow

**Date**: March 25, 2026
**Area**: Services Domain (Main Services, Sub-Services, Details, Pricing)

This report analyzes the implementation of the `Services` domain layer in the Fresh Home project, focusing on fetching, offline-first caching, real-time synchronization, and cross-application data flow (Admin vs. Customer apps).

---

## 1. Architecture Overview
The system employs a **Repository Pattern** with a **Remote-Local Data Source** paradigm, fully adhering to Clean Architecture principles in a Flutter monorepo environment.

- **Repository (`domain/repositories/service_repository.dart`)**: The single source of truth interfacing with Usecases.
- **Local Cache (`data/datasources/service_local_datasource.dart`)**: Hive (NoSQL) for high-speed offline reads.
- **Remote Source (`data/datasources/service_remote_datasource.dart`)**: Supabase (PostgreSQL) using PostgREST.

---

## 2. Syncing Strategy (The "Manifest" Approach)
- **Concept:** Instead of brute-forcing checks on every individual service, the system fetches a "manifest" from the `services_updated` tracking table.
- **Mechanism:** The Customer App compares the remote timestamps against local Hive timestamps. 
- **Delta Sync:** Fetching happens conditionally in `getMainServices()` and `getSubServices()`. If the remote manifest is newer, a targeted synchronization begins.
- **Offline-First:** If the internet connection fails, the repository seamlessly yields the cached entities from Hive (`Right(entity)`).

---

## 3. Real-Time Synchronization (WebSockets)
- **Component:** `ServiceRealtimeSyncDataSource`
- **Listener:** Hooks into Postgres `INSERT`, `UPDATE`, `DELETE` events for `main_services` and `sub_services`.
- **Conflict Resolution:** Employs a defensive strategy. If a real-time event fires, the app checks the `PendingActionHiveModel` queue. If the user has a *newer* offline edit pending for that entity, the incoming remote event is ignored to prevent destructive overwriting.

---

## 4. Sub-Service Advanced Details Flow (Deep Dive)
A specific end-to-end trace mapping the `details`, `notIncluded`, and `price_config` workflows:

### A. Admin UI (Data Entry)
- **Component:** `SubServiceDetailsEditorPage` (fresh_home_admin)
- **Architecture:** Localized Dynamic UI.
- **Execution:** Successfully compiles complex localized sub-components into the Domain Entity `SubServiceEntity`. The state management (`AdminSubServicesCubit`) safely handles the mapping.

### B. State & Repository (The Push)
- **Flow:** `UpdateSubServiceUseCase` → `ServiceRepositoryImpl.updateSubService()`.
- **Status:** Exceptional robustness. It employs an **Offline-First Optimistic Queue**.
  - **Online:** Sends via `_mapToSupabaseSub()`, updates Hive, outputs `Right(SubServiceEntity)`.
  - **Offline:** Saves the change permanently to the Hive `sub_services_box`, stores the raw JSON payload in a background queue (`PendingActionHiveModel`), and instantly yields success back to the UI.

### C. Network Serialization (The Bridge)
- **Component:** `ServiceMapper` and `ServiceRemoteDataSourceImpl._mapToSupabaseSub()`.
- **Output:** 
  - `details` maps exactly to the `'details'` Postgres column.
  - `notIncluded` maps to `'not_included'`.
  - `price` maps to `'price_config'`.
- **Postgres JSONB Anomaly:** For older sub-services that never had details added, PostgREST serves `null` for the `details` column upon fetching.

### D. Customer UI & Deserialization (The Pull)
- **Flow:** `ServiceRemoteDataSourceImpl._mapSubService()`
- **Defensive Engineering:** The deserializer fortifies the pipeline against `null` returns or malformed database objects:
  - If `details` arrives as literally `null`, it dynamically casts it to an empty list `[]`.
  - Nested objects (like Localization maps `ar` and `en`) are strictly cast and assigned default values if partial data is sent.
- **Display:** `ServiceDetailsPage` → `DetailsOptionsSection`.
  - Uses conditional rendering: `if (details == null || details.isEmpty) return SizedBox.shrink();`.
  - **Result:** Instead of rendering blank cards or throwing errors, the UI collapses cleanly.

---

## 5. Performance Footprint
- **Reads:** ✅ Ultra-fast (Hive-first retrieval guarantees 60fps scrolling on the Flutter main thread).
- **Network Traffic:** ✅ Efficient. Employs Delta sync to pull only changed manifest IDs.
- **Queue processing:** The pending sync queue processes gracefully on app restart using FIFO (First-In, First-Out).

## 6. Final Verdict
The technical layout governing the Service Module is enterprise-grade. The separation of concerns between `Entities`, `Mappers`, and `DataSources` allows the UI to remain incredibly resilient to backend absences while giving full offline reliability.
