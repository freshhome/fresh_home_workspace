# Fresh Home: Environment Setup & Build Guide

This guide describes how to configure, run, and compile the applications within the **Fresh Home** monorepo using compile-time environment variables and localized keystore signing parameters.

---

## 1. Environment Configurations

Secrets and connection parameters (e.g. Supabase credentials) are isolated from source code using compile-time constants injected via `--dart-define-from-file`.

### Config Files Location
All environment config files are stored in the root workspace under:
```
config/environments/
├── development.json
├── staging.json
├── production.json
└── env.json.example
```

Each environment file utilizes the following format:
```json
{
  "ENVIRONMENT": "production",
  "SUPABASE_URL": "https://your-project-id.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-string"
}
```

### Launching the Application

To run or build any of the apps (Customer, Staff, Admin) under a specific environment, append the `--dart-define-from-file` parameter:

#### Run Development (Default fallback is development database)
```bash
flutter run
# OR explicitly:
flutter run --dart-define-from-file=../../config/environments/development.json
```

#### Run Staging
```bash
flutter run --dart-define-from-file=../../config/environments/staging.json
```

#### Build Production APK
```bash
flutter build apk --release --dart-define-from-file=../../config/environments/production.json
```

*Note: The relative path depends on your active terminal directory. If executing from the workspace root (e.g. via melos), adjust the path to `config/environments/development.json`.*

---

## 2. Release Signing Security (Android)

Release signing properties must be stored locally on your machine and never committed to Git.

### Setup Instructions
1. Inside the `android/` directory of the application you want to sign (e.g., `apps/fresh_home_admin/android/`), create a file named `key.properties`.
2. Populate the file with your keystore path and password parameters:
   ```properties
   storeFile=/path/to/your/upload-keystore.jks
   storePassword=yourKeystorePassword
   keyAlias=yourKeyAlias
   keyPassword=yourKeyPassword
   ```
3. Ensure the `.keystore` or `.jks` file is kept outside of the repository directory or properly ignored. The project's root `.gitignore` is pre-configured to ignore all `key.properties` and keystore files as a safety fallback.
4. **Automatic Fallback**: If the `key.properties` file is missing, the build process will automatically fall back to using the default debug signature so compilation is not disrupted.
