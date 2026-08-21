# Fresh Home Authentication Production Execution

## Current Status

```text
Current Phase: Phase 4 — Password Recovery E2E Flow & Phase 6 Production Gate
Current Step: Step 4.1 — Testing Email Verification & Password Recovery Deep Linking
Overall Status: IN_PROGRESS (Phases 1, 2, 3, 5 are COMPLETED)
Last Updated: 2026-08-20
Next Action: Perform Password Recovery & Signup Email Verification E2E test.
```

## Progress

| Phase | Status | Owner | Evidence / Details |
|---|---|---|---|
| Phase 1 — Supabase Dashboard Configuration | COMPLETED | HUMAN | `HUMAN CONFIRMED` — Site URL set to `https://freshhomeeg.com/` and 8 Allowed Redirect URLs configured in Supabase. |
| Phase 2 — Flutter Deep Link Configuration | COMPLETED | AGENT | `CODE VERIFIED` — `AndroidManifest.xml` updated for `admin`, `staff`, `customer` apps to accept scheme deep links without host restrictions. iOS `Info.plist` checked. |
| Phase 3 — AuthListener & Router Recovery Handling | COMPLETED | AGENT | `CODE VERIFIED` — `AuthListener` handles `AuthChangeEvent.passwordRecovery`, `AppRouterConfig` explicitly allows `AppRoutes.resetPassword`. |
| Phase 4 — Password Recovery E2E Flow | IN_PROGRESS | MIXED | `CODE VERIFIED` — `ResetPasswordPage` & `updateUser` ready. Awaiting E2E manual device verification. |
| Phase 5 — Logout & FCM Token Consolidation | COMPLETED | AGENT | `CODE VERIFIED` — `SignOutUseCase` updated with automatic FCM token cleanup across all logout paths. |
| Phase 6 — Production Gate | IN_PROGRESS | MIXED | Currently running E2E validation matrix across `admin`, `staff`, and `customer` apps. |

---

## Phase Log & Task Details

### Phase 1 — Supabase Dashboard Configuration
* **Status**: `WAITING_FOR_HUMAN`
* **Started**: 2026-08-20
* **Tasks**:
  - [ ] Update Supabase Site URL to `https://freshhomeeg.com/`
  - [ ] Add `https://freshhomeeg.com/*` to Additional Redirect URLs
  - [ ] Add `https://www.freshhomeeg.com/*` to Additional Redirect URLs
  - [ ] Add `com.freshhome.customer://*` to Additional Redirect URLs
  - [ ] Add `com.freshhome.staff://*` to Additional Redirect URLs
  - [ ] Add `com.freshhome.admin://*` to Additional Redirect URLs
* **Human Action Required**: Yes (Must be performed in Supabase Dashboard).
* **Next Step**: User confirms Supabase Dashboard URL configuration.

---

### Phase 2 — Flutter Deep Link Configuration
* **Status**: `COMPLETED`
* **Started**: 2026-08-20
* **Completed**: 2026-08-20
* **Tasks**:
  - [x] Inspect `apps/fresh_home_admin/android/app/src/main/AndroidManifest.xml`
  - [x] Inspect `apps/fresh_home_staff/android/app/src/main/AndroidManifest.xml`
  - [x] Inspect `apps/fresh_home_customer/android/app/src/main/AndroidManifest.xml`
  - [x] Update intent filters to allow scheme deep links (`com.freshhome.admin`, `com.freshhome.staff`, `com.freshhome.customer`) without `login-callback` host restriction
  - [x] Verify iOS `Info.plist` `CFBundleURLSchemes` across all 3 apps
* **Files Changed**:
  - `apps/fresh_home_admin/android/app/src/main/AndroidManifest.xml`
  - `apps/fresh_home_staff/android/app/src/main/AndroidManifest.xml`
  - `apps/fresh_home_customer/android/app/src/main/AndroidManifest.xml`
* **Evidence**: `CODE VERIFIED` — AndroidManifest intent filters updated and validated.

---

### Phase 3 — AuthListener & Router Recovery Handling
* **Status**: `COMPLETED`
* **Started**: 2026-08-20
* **Completed**: 2026-08-20
* **Tasks**:
  - [x] Update `AuthListener` to catch `AuthChangeEvent.passwordRecovery`
  - [x] Route user to `AppRoutes.resetPassword` on `passwordRecovery` event
  - [x] Update `AppRouterConfig` guard to allow `AppRoutes.resetPassword` without redirecting recovery session to home
* **Files Changed**:
  - `packages/shared_features/lib/src/features/authentication/presentation/widgets/auth_listener.dart`
  - `packages/shared/lib/core/routing/app_router_config.dart`
* **Evidence**: `CODE VERIFIED` — Listener and Router exception implemented cleanly without breaking architecture.

---

### Phase 4 — Password Recovery E2E Flow
* **Status**: `IN_PROGRESS`
* **Started**: 2026-08-20
* **Tasks**:
  - [x] Verify `ResetPasswordPage` form handling & `updateUser()` call
  - [ ] E2E Manual Test: Request reset -> Click link in email -> App opens `/reset-password` -> New password saved -> Old password rejected -> New password accepted
* **Human Action Required**: Pending Phase 1 setup confirmation.

---

### Phase 5 — Logout & FCM Token Consolidation
* **Status**: `COMPLETED`
* **Started**: 2026-08-20
* **Completed**: 2026-08-20
* **Tasks**:
  - [x] Consolidate FCM token deletion inside `SignOutUseCase.call()`
  - [x] Update `auth_di.dart` DI registration
* **Files Changed**:
  - `packages/shared_features/lib/src/features/authentication/domain/use_cases/sign_out.dart`
  - `packages/shared_features/lib/src/features/authentication/di/auth_di.dart`
* **Evidence**: `CODE VERIFIED` — FCM token cleanup executed automatically across all logout entry points.

---

### Phase 6 — Production Gate
* **Status**: `PENDING`
* **Tasks**:
  - [ ] Run full E2E validation matrix across Customer, Staff, and Admin apps.
