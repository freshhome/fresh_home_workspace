# Home Context (home_context.md)

## Overview
Common shell feature for the application, providing bottom navigation, scaffold, and entry points to core business features.

## Architecture
Shell-based routing container.

## Rules
- **App Specificity**: While shared in name, the `home` feature is implemented specifically in both Customer and Staff apps to cater to their respective primary workflows.
- **Navigation Focused**: No business logic; only manages the high-level application layout.
