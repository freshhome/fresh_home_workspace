# Technical Verification Audit: Unified Services System

This verification audit reviews the current services data layer implementation (Supabase, Hive caching, repositories, and realtime syncing) to assess its production readiness and identify structural risks before migrating the UI screens.

---

## 📊 1. Technical Audit Summary

| Audit Dimension | Status | Primary Findings | Recommendations |
| :--- | :--- | :--- | :--- |
| **1. Data Contract Stability** | <span style="color:orange; font-weight:bold;">RISK</span> | The database schema, mapper, and repository use the unified `ServiceEntity` as the single source of truth. However, the legacy `MainServiceEntity` and `SubServiceEntity` wrappers are still heavily referenced in `shared_features` presentation logic. | Keep mapping layers stable during initial UI refactoring, then deprecate legacy entities. |
| **2. Tree Structure Rules** | <span style="color:green; font-weight:bold;">PASS</span> | The adjacency list tree building in the repository (`parentId == null` for roots, `parentId != null` for children, and `isBookable == true` for leaf nodes) is correctly implemented and strictly followed. | None. |
| **3. Cache & Performance Layer** | <span style="color:green; font-weight:bold;">PASS</span> | The `_adjacencyList` cache is built once upon database loading or syncing. All retrieval queries run in $O(1)$ time in memory. UI layers perform zero list processing. | None. |
| **4. Sync Behavior Safety** | <span style="color:green; font-weight:bold;">PASS</span> | Background updates commit to Hive and update the cache asynchronously. Watcher updates are debounced by 100ms to prevent multiple redundant rebuilds and flickering. | Ensure UI state models use Equatable comparison to avoid redraw triggers on identical datasets. |
| **5. Legacy Dependency Risk** | <span style="color:orange; font-weight:bold;">RISK</span> | `BookingFlowCubit` and `service_selection_page.dart` depend directly on legacy entities and `getMainServices()`. Modifying core properties could cause divergence. | Refactor these UI controllers to consume the unified `ServiceEntity` and unified tree use cases. |

---

## 🔍 2. Deep Dive Analysis

### A. Data Contract Stability
* **Status**: <span style="color:orange; font-weight:bold;">RISK</span>
* **Analysis**:
  - The core data pipeline is solid:
    `Supabase (services table) ➔ ServiceRemoteModel ➔ ServiceHiveModel ➔ ServiceEntity`
  - All database columns map cleanly to entity fields (Multilingual title/description, instructions, prices, details, status).
  - The risk is that the presentation layer (`packages/shared_features`) still uses `MainServiceEntity` and `SubServiceEntity` for its UI state.
* **Minimal Fix**: 
  - Retain `ServiceMapper.serviceToMainServiceEntity` and `ServiceMapper.serviceToSubServiceEntity` as the compatibility bridge. They map the unified model to legacy objects safely without database or cache divergence.

### B. Tree Structure Rules
* **Status**: <span style="color:green; font-weight:bold;">PASS</span>
* **Analysis**:
  - `ServiceRepositoryImpl._buildTreeCache()` correctly structures the adjacency lists:
    ```dart
    final parentId = service.parentId;
    _adjacencyList[parentId]!.add(service);
    ```
  - Bookable leaf nodes are categorized cleanly:
    ```dart
    if (service.isBookable) {
      _bookableServices.add(service);
    }
    ```
  - Soft-deleted or inactive items are excluded from tree-building:
    ```dart
    if (service.status != ServiceStatus.active) {
      continue;
    }
    ```
  - There is zero parsing or tree rebuilding code in the UI controllers or datasources, meaning tree boundaries are strictly maintained.

### C. Cache & Performance Layer
* **Status**: <span style="color:green; font-weight:bold;">PASS</span>
* **Analysis**:
  - The repository compiles the tree cache *internally* in memory. 
  - Calls to `getRootServices()`, `getChildren()`, and `getBookableServices()` return reference lookups from pre-built collections (`_adjacencyList[null]` or `_bookableServices`).
  - Re-compilation of the tree only occurs on local data insertion or sync, preventing high-frequency CPU computations.

### D. Sync Behavior Safety
* **Status**: <span style="color:green; font-weight:bold;">PASS</span>
* **Analysis**:
  - The repository constructor listens to local Hive changes using `Hive.box(...).watch()`.
  - A **100ms debounce timer** (`_watcherDebounce`) is used:
    ```dart
    _watcherDebounce?.cancel();
    _watcherDebounce = Timer(const Duration(milliseconds: 100), () {
      _reloadCacheAndRebuildTree();
    });
    ```
  - This ensures that if 50 items are cached during incremental sync, `_reloadCacheAndRebuildTree` runs only once.
  - The new query APIs are `Future`-based, meaning background synchronization does not force immediate redraws on active screens until a user triggers a refresh or navigates to a page.

### E. Legacy Dependency Risk
* **Status**: <span style="color:orange; font-weight:bold;">RISK</span>
* **Analysis**:
  - `BookingFlowCubit` exposes:
    ```dart
    void selectService(SubServiceEntity subService)
    ```
  - `service_selection_page.dart` initializes by listening to:
    ```dart
    cubit.serviceRepository!.getMainServices().listen(...)
    ```
  - This stream relies on `getMainServices()` which runs a full sync and yields `MainServiceEntity` models. If we modify the underlying schema of `ServiceEntity` without updating these wrappers, the compiler will not catch errors on legacy pages until runtime.

---

## 🛡️ 3. Recommended Minimal Fixes

To prepare the codebase for UI integration safely, we recommend the following minimal fixes:

1. **Keep the Bridge Mapper Intact**:
   Maintain `ServiceMapper` compatibility converters (`serviceToMainServiceEntity` and `serviceToSubServiceEntity`). Do not deprecate them until the UI is fully migrated.
2. **Refactor BookingFlowCubit Step-by-Step**:
   - Instead of receiving `SubServiceEntity` in `selectService()`, update `BookingFlowCubit` to accept `ServiceEntity` and assert `service.isBookable == true`.
   - Update the UI to consume `ServiceEntity` list directly from `GetRootServicesUseCase` and `GetChildrenUseCase` instead of invoking `getMainServices()` stream.
3. **Use Equatable for UI State**:
   - Verify that the models emitted in UI states use `Equatable` or custom `operator ==` overrides. This protects against visual list flickering if identical lists are emitted during background sync runs.

---

## 📈 UI Integration Readiness Score

Based on this audit, the data and caching architecture is **highly ready** for UI integration.

$$\text{Readiness Score: } 90\%$$

* **Why not 100%?**: The remaining 10% is the legacy UI dependency risk inside `BookingFlowCubit` and `service_selection_page.dart`, which will be resolved during the UI migration phase.
