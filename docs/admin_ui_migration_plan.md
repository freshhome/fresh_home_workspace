# Admin UI Technical Audit & Migration Plan: Tree-Based Services

This document presents a comprehensive technical audit of the current administrative features for managing services and details a safe, progressive migration plan to adapt these screens to the new **Tree-Based Services System**.

---

## 📐 1. Service Contract Definition

Before writing any UI or migration code, we define the strict contract for `ServiceEntity` to prevent data model divergence and regression.

### A. Immutable Fields (Server/System Managed)
* **`id`** (`String`): Set at creation as a UUID. It remains permanent and cannot be modified.
* **`updatedAt`** (`DateTime`): Set by the database/repository whenever a mutation is committed. It is never edited directly by the user.

### B. Editable Fields (Common)
* **`parentId`** (`String?`): References the parent category node. Editing this field moves the service/category to a new location in the tree. Can be set to `null` to make the node a root category.
* **`isBookable`** (`bool`): Determines if the node can be booked (leaf node) or if it is a category. 
* **`title`** (`Map<String, String>`): Multilingual localizable names (keys like `ar`, `en`).
* **`description`** (`Map<String, String>`): Multilingual descriptions.
* **`order`** (`int`): Display order sequence.
* **`status`** (`ServiceStatus`): Lifecycle status (`active` or `archived` for soft-deletion).

### C. Conditional Editable Fields (Only if `isBookable == true`)
If `isBookable` is `true`, the following configurations must be supplied:
* **`price`** (`PriceEntity`): Configures base rates, options/extras, and dynamic calculation fields.
* **`details`** (`List<DetailEntity>`): Structured inclusions and bullet points.
* **`notIncluded`** (`NotIncludedEntity`): Explicit exclusions.
* **`instructions`** (`Map<String, String>?`): Checklist/instructions for booking.

### D. Asset & Future Extension Guidelines
* **`image`** (`String?`): Stored as a single string. The UI must treat this field strictly as a **Service Icon** or category thumbnail.
* **`images` / Gallery** (`List<String>`): Future feature. Will be added to the schema later.
* **Structured Data**: Structured data (e.g. requirements, inclusions) must continue using `details` and `notIncluded` fields. We will **never** use a generic `metadata` JSON block to bypass these structured fields.

---

## 📊 2. Current State Analysis & Audit

### A. Service Listing Feature
* **Current Implementation**:
  - Main categories are fetched in `services_management_page.dart` using `ServicesManagementCubit` (`GetMainServicesUseCase`).
  - Sub-services are fetched in `sub_services_page.dart` using `AdminSubServicesCubit` (`GetSubServicesUseCase`).
* **Architectural Legacy Issues**:
  - **Coupling to Wrappers**: The admin UI relies directly on `MainServiceEntity` and `SubServiceEntity` instead of the unified `ServiceEntity`.
  - **Static Two-Tier Hierarchy**: The navigation assumes a hardcoded 2-level structure. There is no capability to display mid-level sub-categories or deep nested trees.

### B. Service Edit Feature (CRUD operations)
* **Create & Update**:
  - Managed via `service_form_page.dart` and `sub_service_form_page.dart` / `sub_service_details_editor_page.dart`.
  - Uses legacy `AddMainServiceUseCase`, `UpdateMainServiceUseCase`, `AddSubServiceUseCase`, `UpdateSubServiceUseCase`.
* **Deletion**:
  - Uses legacy `DeleteMainServiceUseCase` and `DeleteSubServiceUseCase`.
  - **Critical Flaw**: In the repository layer, these legacy delete use cases call stub functions that return `Right(unit)` without committing any soft-delete state to Supabase. This means deletions in the current admin panel are completely non-functional on the database level.
* **Tree Manipulations (Moving Nodes / Toggling Bookable)**:
  - **Moving (Change `parentId`)**: Not supported. Parent-child relationships are fixed at creation.
  - **Toggle `isBookable`**: Not supported. Node type is determined statically by whether it is a "Main" or "Sub" service.

---

## 🛡️ 3. Risk Assessment

| Risk Area | Severity | Description | Mitigation |
| :--- | :--- | :--- | :--- |
| **Silent Deletion Failures** | <span style="color:red; font-weight:bold;">CRITICAL</span> | Admins deleting services see a success message, but the data is never deleted or archived on Supabase. | Deprecate `deleteMainService`/`deleteSubService` use cases immediately and replace them with `updateService(status = archived)`. |
| **Invalid Hierarchies & Loops** | <span style="color:red; font-weight:bold;">HIGH</span> | Editing a service's parent ID without circular-path checks can lock up the client-side tree compiler in recursive loops. | Implement UI and Cubit-level parent validation checking that `newParentId != service.id` and is not a descendant of `service.id`. |
| **Broken Inclusions/Exclusions** | <span style="color:orange; font-weight:bold;">HIGH</span> | `SubServiceEntity` expects `details` and `notIncluded` to be non-nullable. If an admin edits a service using the unified model and saves null values, the Customer app booking flow will crash. | The mapper must enforce fallback default empty lists/objects when converting from `ServiceEntity` to `SubServiceEntity`. |

---

## 🔄 4. Progressive Migration Plan

We will adapt the Admin panel step-by-step, preserving the existing state management files to minimize regression.

### Phase 1: Core Action Fixes (Urgent CRUD Repairs)
* **Goal**: Solve silent delete failures and ensure basic CRUD operations write to the new unified table.
* **Steps**:
  1. Refactor deletion in `ServicesManagementCubit` and `AdminSubServicesCubit` to call `UpdateServiceUseCase` (setting `status = ServiceStatus.archived`).
  2. Map category mutations to `ServiceEntity` with `isBookable = false` and `parentId = null`.
  3. Map service mutations to `ServiceEntity` with `isBookable = true` and `parentId = categoryId`.

### Phase 2: Navigation & Traversal Refactoring
* **Goal**: Support nested categories and unified listing without adding a heavyweight unified Cubit.
* **Steps**:
  1. Refactor `ServicesManagementCubit` to load root services (`parentId == null`) from `GetRootServicesUseCase` instead of `GetMainServicesUseCase`.
  2. Refactor `AdminSubServicesCubit` to load sub-nodes from `GetChildrenUseCase(parentId)` instead of `GetSubServicesUseCase(categoryId)`.
  3. Replace the legacy listings with a folder-based navigation screen. A user clicks a category node (which has `isBookable = false`) to drill down, calling `AdminSubServicesCubit.loadSubServices(parentId)`.

### Phase 3: Advanced Tree Editor & Rule Enforcer
* **Goal**: Implement visual tree controls and strict hierarchy validations.
* **Steps**:
  1. **Parent Selector Form**: Add a drop-down/search selector for `parentId`. Filter out the service's own node and all its descendants to prevent circular loops.
  2. **Bookable Toggle Validation**: If `isBookable` is toggled from `false` to `true`, verify that the node has 0 child nodes in `_adjacencyList`.
  3. **Reassignment / Cascade Purge Form**: When archiving a category, present a dialog asking the admin to either:
     - Soft-delete all child services recursively (cascade archive).
     - Reassign all child services to a different category parent.
