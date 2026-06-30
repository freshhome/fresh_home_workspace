# Fresh Home Motion Design System (`fresh_home_motion`)

This package is the core foundation for all animations, transitions, loading elements, and interactive gestures in the Fresh Home platform. It enforces performance guardrails, consistent visual timing, and platform adaptivity monorepo-wide.

## Purpose
The primary purpose of this package is to isolate presentation motion properties and transition engines from application business logic, states, and DB query routines. It ensures that the Fresh Home brand visual identity remains consistent across Customer, Technician, and Admin Apps.

## Package Structure
All implementation details are organized within the `lib/src/` folder:
*   `lib/src/foundation/`: Core interfaces and platform capability adapters.
*   `lib/src/tokens/`: Static design tokens (timing, curves, opacity, scale, and elevation).
*   `lib/src/widgets/`: Optimized visual primitives and base animation widgets.
*   `lib/src/transitions/`: Standard GoRouter and custom bottom sheet transition builders.
*   `lib/src/loading/`: Reusable content placeholder builders and shimmer elements.
*   `lib/src/feedback/`: Snappy tactile/haptic feedback integration logic.
*   `lib/src/utilities/`: Accessibility helpers and context extensions (e.g. reduced motion).
*   `lib/src/testing/`: Mock clocks and tools for deterministic widget tests in CI pipelines.

## Public API & Export Rules
Direct imports of subfolders under `src/` (e.g. `import 'package:fresh_home_motion/src/tokens/...'`) are **strictly prohibited**. 

All public-facing features, widgets, classes, and tokens are exported centrally in the barrel file:
```dart
import 'package:fresh_home_motion/fresh_home_motion.dart';
```

## Usage Philosophy
1.  **Always Consume Tokens:** Hardcoding durations, curves, or scales inside application widgets is forbidden. Use `FHMotionTokens` variables.
2.  **Modularity first:** Every animation widget must have a single responsibility (e.g. handle fade, scale, or layout translate independently).
3.  **Performance Mindset:** Utilize repaint boundaries and GPU-driven animations to prevent layout triggers and drop frames.

## Development Rules
*   Do not import `packages/shared`, feature packages, or app directories. This package must remain a dependency-free leaf node.
*   All controllers, tickers, and listeners must be safely disposed of.
*   Reduced motion properties must be queried from `ReducedMotionContextExtension` and respected by omitting slide/scale paths when active.
