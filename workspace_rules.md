# Workspace Rules - Fresh Home

Project-specific engineering rules for the Fresh Home platform.

---

# 1. Project Overview

Fresh Home is a Flutter monorepo platform connecting customers with home service technicians.

Applications:

* fresh_home_admin
* fresh_home_customer
* fresh_home_staff

Shared Packages:

* packages/shared
* packages/shared_features

Primary Backend:

* Supabase

Architecture:

* Clean Architecture
* Feature First Structure
* Cubit State Management

Priority:

Speed of delivery is important, but architectural integrity must be preserved.

---

# 2. Monorepo Rules

Directory Structure:

apps/

* fresh_home_admin
* fresh_home_customer
* fresh_home_staff

packages/

* shared
* shared_features

supabase/

* migrations
* schema
* functions

---

# 3. Package Boundaries

packages/shared

Contains:

* Core
* DI
* Storage
* Networking
* Base Models
* Common Utilities

packages/shared_features

Contains:

* Auth
* Splash
* Profile
* Notifications
* Reusable Features

Must not contain application-specific business logic.

Application-specific logic belongs inside the corresponding app feature.

---

# 4. Feature Development Standard

Every feature should follow:

feature/

* data
* domain
* presentation

Preferred flow:

Entity
→ Repository Contract
→ Repository Implementation
→ Data Source
→ UseCase
→ Cubit
→ UI

---

# 5. Feature Context Files

Every feature should contain:

<feature_name>_context.md

The context file must describe:

* Feature purpose
* Business rules
* State management
* Data flow
* Related tables
* Related RPCs
* Important files

Before analyzing a feature:

Read its context file first.

Use the context file to reduce token usage and accelerate onboarding.

---

# 6. State Management

State Management:

* flutter_bloc
* Cubit pattern

Rules:

* UI communicates with Cubits
* Cubits communicate with UseCases
* UseCases communicate with Repositories
* UI never accesses repositories directly

---

# 7. Supabase Authority

Supabase PostgreSQL is the source of truth.

Critical business logic belongs to the database.

Examples:

* Pricing
* Booking lifecycle
* Assignment workflows
* Security validation

Avoid duplicating critical business rules inside Flutter.

---

# 8. Migration Safety

All schema changes must be implemented through new migration files.

Never modify previously applied migrations.

Before creating migrations:

1. Review existing migrations.
2. Review schema files.
3. Analyze impact.
4. Explain changes.

Never:

* Drop tables without approval
* Remove columns without approval

---

# 9. Pricing Governance Rules

Pricing is server authoritative.

Before changing pricing:

* Review pricing pipeline stages.
* Review pricing RPCs.
* Review pricing migrations.
* Review pricing context documentation.

Validate all pricing changes through simulation workflows.

Never introduce a parallel pricing engine.

Never bypass server-side calculations.

---

# 10. Storage Rules

Supabase Storage is the central asset repository.

Before deleting assets:

* Check service references.
* Check category references.
* Check shared icon references.

Prevent orphaned assets.

---

# 11. Shared Icons Library

Always reuse existing icons before creating new assets.

Maintain icon usage tracking.

Never delete shared assets without dependency verification.

---

# 12. Authentication & Authorization

Authentication:

* Supabase Auth

Authorization:

* Role-based access

Roles:

* client
* technician
* admin

RLS policies must remain consistent with role permissions.

---

# 13. Notifications

Notifications are part of booking and operational workflows.

When modifying booking states:

Review notification side effects and related flows.

---

# 14. Dependency Injection

All new services, repositories, use cases, and cubits must be registered through the appropriate DI module.

Verify DI registration before completion.

---

# 15. Routing

Routing is managed through GoRouter.

Any new screen must be integrated into the routing system.

Verify navigation paths after implementation.

---

# 16. Current Priorities

Current strategic focus:

1. Technician Operations
2. Pricing Governance Enhancements
3. Booking Lifecycle Stability
4. Admin Operations Tools

Future roadmap:

* Online Payments
* Maps & Live Tracking
* Advanced Analytics

These future features should not introduce premature complexity into current implementations.

---

# 17. Delivery Philosophy

Fresh Home prioritizes:

1. Working solutions
2. Clean Architecture
3. Reusability
4. Maintainability

Avoid overengineering.

Prefer simple, scalable implementations that can evolve with the product.
