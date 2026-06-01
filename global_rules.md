# Global Rules & AI Collaboration Standards

This document establishes the global development standards, workflows, and collaboration preferences for coding and architecture tasks. These rules are generic, reusable across different projects, and must be strictly adhered to by any AI assistant or developer working on the codebase.

---

## 1. Communication Style

- **Conciseness & Clarity**: Keep conversations focused and brief. Avoid conversational filler or unnecessary explanations.
- **Decision-Driven**: Highlight open questions, alternative approaches, and design trade-offs early. Group complex choices into structured options.
- **Markdown-Centered**: Standardize updates using GitHub-style markdown syntax.
- **Reference-Heavy**: Use absolute file paths formatted as clickable markdown links (e.g. `[filename.dart](file:///path/to/filename.dart)`) and link directly to relevant symbols, classes, or line ranges.

---

## 2. Planning Requirements

For any task that introduces structural modifications, new features, or architectural extensions (excluding trivial style or comment tweaks):
1. **Research Phase**: Perform comprehensive research before writing any code or modifying components. 
2. **Implementation Plan (`implementation_plan.md`)**:
   - Write out a structured design doc highlighting modified, new, and deleted files.
   - List any critical user reviews or open questions.
   - Request user feedback (set `request_feedback = true` in metadata) and wait for explicit approval.
3. **Task Checklist (`task.md`)**:
   - Create a living checklist tracking task progress (`[ ]` for pending, `[/]` for in-progress, `[x]` for completed).
4. **Validation Walkthrough (`walkthrough.md`)**:
   - Outline what was tested, show terminal test runs, and include links/media verifying changes before declaring success.

---

## 3. Code Quality Standards

- **Clean Architecture Principles**: Maintain strict boundaries between layers:
  - **Domain Layer**: Contains pure business logic (entities, use cases, repository contracts). It must be independent of external packages, frameworks, database drivers, and UI widgets.
  - **Data Layer**: Implements the repositories using data sources (local caches, remote APIs). Translates external payloads to domain models.
  - **Presentation Layer**: Consists of UI components, widgets, routes, and state managers. Interacts strictly via use cases or repository abstractions (never direct API calls).
- **Strong Typing**: Avoid dynamic, weak types, and force type casting where possible. Build robust type mappers (`mapper.dart`) rather than passing raw JSON maps across layer boundaries.
- **Strict Error Handling**: Use helper paradigms (like `Either<Failure, Success>` or functional programming styles) to represent operations that can fail, ensuring caller components handle exceptions safely and explicitly.
- **Dependency Injection**: Utilize centralized service locators (e.g., `GetIt`) to decouple client classes from specific concrete implementations.

---

## 4. Documentation Expectations

- **Context Preservation**: Retain all existing code comments, docstrings, and headers unless explicitly requested otherwise.
- **Living Context Files**: Each major module should have a local `<feature>_context.md` that outlines its purpose, architecture, state management, and rules. Update these files as the code changes.
- **Database Schema Upgrades**: Write structured database migration scripts sequentially. Maintain a corresponding `schema/` directory describing the current base state, separate from active migrations.
- **Aesthetic Guidelines**: Maintain consistency in naming, code styling, lint options, and configuration schemas.

---

## 5. Refactoring Behavior

- **Safety First**: Prioritize non-breaking changes. Avoid deleting or renaming critical APIs without first deprecating them (`@deprecated`).
- **Feature Flags**: Wrap unstable features, migration bridges, or new layouts behind centralized flags (e.g., config parameters or feature flags) to enable rapid rollback or partial deployment.
- **Regression Checks**: Ensure that refactoring does not break existing test cases, database constraints, or security rules (RLS/JWT).

---

## 6. AI Assistant Guidelines

- **Context-First Verification**: Before planning, the AI must check the local Knowledge Item (KI) summaries and search transcripts of previous conversations to avoid repeating mistakes or recreating existing logic.
- **Real-World Verification**: Never assume code works. Run automated test suites, build checks, and compilers locally before reporting status.
- **Zero Placeholders**: Do not output code with comments like `// TODO: implement later` or placeholder stubs. If an implementation is requested, write the complete logic. If an asset is missing, generate a working demonstration or request visual validation.
- **Clarity on Uncertainty**: If a constraint, design pattern, or configuration is not fully traceable in the codebase, explicitly note: `"Needs manual verification."`
