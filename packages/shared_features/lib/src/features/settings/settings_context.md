# Settings Context (settings_context.md)

## Overview
Shared feature for application-wide settings, including language preference, theme selection, and notification toggles.

## Architecture
- **Cubit**: `SettingsCubit` manages the state of user preferences.
- **Data**: Uses local storage (Shared Preferences) for persistence.

## State Management
Persistent state synchronized with the app's global theme and localization providers.

## Data Flow
UI (Settings Screen) → `SettingsCubit` → Local Storage.

## Rules
- **Consistency**: Ensure settings changes are reflected immediately across the app.
- **Localization**: All text must be internationalized.
