# Authentication Diagnostic Debug Log Points Report

This report outlines the files and methods instrumented with debug logging to analyze identity-linking behavior.

---

## 1. Modified Files and Instrumented Methods

The following two files were modified to introduce diagnostic logging around the key authentication entry points:

### File 1: [supabase_auth_data_source.dart](file:///d:/fresh_home_workspace/packages/shared_features/lib/src/features/authentication/data/data_sources/supabase_auth_data_source.dart)
* **`signUp` (Email Sign Up)**: Prints email payload, returns user ID, email, providers list, identities, session status, or full Supabase exceptions if they occur.
* **`signIn` (Email Sign In)**: Prints input parameters, returned user info, providers, identities list, and session status, or any error code and message.
* **`signInWithGoogle` (Google Sign In)**: Logs the initiation of the external Google OAuth flow redirect and handles potential initiation exceptions.

### File 2: [auth_listener.dart](file:///d:/fresh_home_workspace/packages/shared_features/lib/src/features/authentication/presentation/widgets/auth_listener.dart)
* **`onAuthStateChange.listen` (Auth State Change Listener)**: Logs every state change event (e.g. `signedIn`, `signedOut`, `tokenRefreshed`) with the user's ID, email, providers lists, identities list, `app_metadata`, and `user_metadata`.

---

## 2. Log Format

All diagnostic logs are wrapped in a recognizable marker box:
```text
================ AUTH DEBUG ================
DEBUG AUTH STATE CHANGE EVENT
eventType: signedIn
userId: abc-123-...
email: test@email.com
providers: [google]
identities: [google:1123432123...]
app_metadata: {...}
user_metadata: {...}
============================================
```

In the event of a Supabase authentication exception, the full exception details and stack trace will print in this format:
```text
================ AUTH DEBUG ================
DEBUG AUTH SIGNUP EXCEPTION
message: ...
statusCode: ...
errorCode: ...
stack trace:
...
============================================
```

---

## 3. Recommended Test Scenarios

Execute the following scenarios sequentially to evaluate the identity-linking rules of your Supabase setup:

### Scenario 1: Google Login with a New Email
1. Open the application.
2. Navigate to the Login screen and click **"Sign in with Google"**.
3. Select or enter a new email address.
4. **Log Expectation**: 
   * Look for `STARTING GOOGLE SIGNIN` followed by `DEBUG AUTH STATE CHANGE EVENT` when redirection returns to the app. 
   * The log should show `eventType: signedIn`, `providers: [google]`, and `identities` containing the Google provider mapping.

### Scenario 2: Logout
1. In the settings section of the app, click **"Sign Out"**.
2. **Log Expectation**: 
   * The `onAuthStateChange` listener will intercept the logout.
   * Look for `DEBUG AUTH STATE CHANGE EVENT` showing `eventType: signedOut` (or `initialSession` clearing) with null user parameters.

### Scenario 3: Attempt Email Sign Up Using the Same Google Email
1. On the registration screen, attempt to sign up with Email/Password using the same email address that was used in Scenario 1.
2. **Log Expectation**:
   * Look for `STARTING AUTH SIGNUP`.
   * **If Email Merging is Enabled**: The signup will update the existing identity or succeed, returning the same user ID.
   * **If Email Merging is Disabled**: The trigger or Supabase will reject the insert, resulting in `DEBUG AUTH SIGNUP EXCEPTION` showing a duplicate key unique constraint violation or an "account already exists" error.

### Scenario 4: Attempt Email Login with That Email
1. Try to log in with Email/Password using that email.
2. **Log Expectation**:
   * Look for `STARTING AUTH SIGNIN`.
   * If the account wasn't successfully merged or email signup was rejected, look for `DEBUG AUTH SIGNIN EXCEPTION` with `errorCode: invalid_credentials` or similar error statuses.
