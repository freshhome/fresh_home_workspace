# Global Rules & AI Collaboration Standards

This document defines the global development standards and AI collaboration workflow.

These rules are reusable across all projects and must be followed before implementation.

---

# 1. Communication

## Language

* Explain concepts, architecture decisions, and reports in Arabic.
* Keep source code, file names, class names, variables, and comments in English.
* Use concise and structured explanations.

## Reporting Style

* Use markdown formatting.
* Prefer bullet points and structured sections.
* Highlight risks, assumptions, and open questions.

---

# 2. Planning Workflow

For any non-trivial task:

1. Analyze existing code first.
2. Search for related implementations.
3. Create an implementation plan.
4. Present risks and affected files.
5. Wait for approval before major modifications.
6. Implement.
7. Generate completion report.

---

# 3. Code Reuse First

Before creating:

* Widget
* Repository
* UseCase
* Model
* Entity
* Service
* SQL Function
* Migration

Search the workspace for existing implementations.

Prefer:

* Reuse
* Extension
* Refactoring

Over duplication.

Never duplicate business logic.

---

# 4. Scope Protection

Only modify files directly related to the requested task.

Do not:

* Refactor unrelated modules
* Rename classes without approval
* Rename files without approval
* Move folders without approval
* Change architecture without approval

---

# 5. Clean Architecture Rules

Maintain strict separation:

## Presentation

Contains:

* Pages
* Widgets
* Cubits
* States

Must not access data sources directly.

## Domain

Contains:

* Entities
* UseCases
* Repository Contracts

Must remain framework independent.

## Data

Contains:

* Models
* Repository Implementations
* Data Sources

Responsible for external integrations.

---

# 6. Dependency Injection

Use GetIt.

All new dependencies must be registered through the appropriate DI module.

Never instantiate repositories or services directly inside UI code.

---

# 7. Strong Typing

Avoid:

* dynamic
* loosely typed structures

Prefer:

* typed models
* mappers
* explicit contracts

---

# 8. Generated Code

Use:

* json_serializable
* build_runner

Do not manually edit generated files.

Regenerate generated code when models change.

---

# 9. Database Safety

Before creating migrations:

1. Review existing migrations.
2. Review schema files.
3. Check dependencies.
4. Explain impact.

Never:

* Modify applied migrations
* Drop tables without approval
* Remove columns without approval

---

# 10. Verification

Never assume implementation correctness.

Verify:

* Build status
* Imports
* DI registration
* Routing integration
* Model mappings

If something cannot be verified:

"Needs manual verification."

---

# 11. Documentation

Preserve existing documentation.

Update relevant context files when architecture or behavior changes.

---

# 12. AI Collaboration Rules

Before implementation:

1. Read project rules.
2. Read architecture documentation.
3. Read relevant feature context file.
4. Search existing code.
5. Plan.
6. Implement.

Always optimize for:

* Maintainability
* Reuse
* Delivery speed

Avoid unnecessary complexity.
