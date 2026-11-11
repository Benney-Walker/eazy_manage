# EazyManage — Desktop Client

EazyManage is a multi-role school ERP desktop app by **Bynex Labs**, built with Flutter for Windows and macOS. It replaces the earlier JavaFX client and talks to the [SchoolManagementSystem](https://github.com/Benney-Walker/SchoolManagementSystem) Spring Boot API.

Principals, administrators, accountants and teaching staff each get a role-specific workspace. It covers:

- academic setup: classes, terms, subjects, grading and holidays
- students and staff
- attendance (view only)
- score entry and conduct
- finance: fees, payments, special fees and expenses
- SMS broadcasts and audit logs
- a reporting center that produces report cards, SBA reports, master score sheets and finance reports as PDFs

Fee payments, score uploads and conduct saves keep working offline. They queue locally and sync when the connection returns.

---

## Requirements

- Flutter (stable) with Dart `^3.12.0`
- **Windows:** Visual Studio with the *Desktop development with C++* workload
- **macOS:** Xcode

## Getting started

```bash
flutter pub get
flutter run -d windows        # or: -d macos
```

### Choosing the API server

The server is picked at build time. See `lib/core/api/api_config.dart`.

| Build | Server |
|---|---|
| `flutter run` (debug/profile) | `http://localhost:8080` |
| `flutter build … --release` | `https://schoolmanagement.api.bynexlabs.com` |
| Any build with `--dart-define=API_BASE_URL=<url>` | `<url>` |

```bash
# Debug build against the production API
flutter run -d windows --dart-define=API_BASE_URL=https://schoolmanagement.api.bynexlabs.com
```

### Tests and analysis

```bash
flutter analyze
flutter test
```

### Code generation

The offline queue is a Drift table. After editing `lib/core/database/app_database.dart`, regenerate the database code and bump `schemaVersion`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Release build

```bash
flutter build windows --release   # build/windows/x64/runner/Release/
flutter build macos --release     # build/macos/Build/Products/Release/
```

---

## Architecture

```
lib/
├── main.dart          Logger + global error hooks, ProviderScope, MaterialApp.router
├── core/
│   ├── api/           ApiClient (Dio), Endpoints, TokenStorage
│   ├── cache/         File-backed read-through cache for reference data
│   ├── connectivity/  Connectivity probe, Drift outbox, SyncEngine, LocalFirstWriter
│   ├── database/      Drift database (offline outbox)
│   ├── logging/       Activity log (file, metadata only)
│   ├── navigation/    Roles, role-filtered nav registry, go_router config
│   ├── notification/  In-app notification center + notify() helper
│   ├── session/       Auth state, login/restore/sign-out
│   ├── theme/         Design tokens (colours, type, spacing), light/dark themes
│   └── widgets/       Shared UI components
├── shell/             App shell: collapsible sidebar, top bar, notification panel
└── features/<name>/
    ├── data/          models, repository, Riverpod providers
    └── ui/            screens, tabs, sheets
```

- **State:** Riverpod. Each feature exposes its repository and data through providers in `data/*_providers.dart`.
- **API:** every request goes through `ApiClient`. Paths come only from `Endpoints`, which encodes query parameters. Failures surface as a typed `ApiException`.
- **Auth:**
  - Login persists the access token, refresh token and profile in secure storage.
  - On a 401, the client refreshes once and retries once.
  - Stored auth is cleared only by an explicit sign-out or when the refresh token itself is rejected.
- **Offline:** offline-capable writes go through `LocalFirstWriter` into the Drift outbox. `SyncEngine` drains the outbox when the connection returns, or from **Settings → Sync now**.
  - Transient failures pause the drain.
  - Entries the server rejects stay queued without blocking later ones.
- **User feedback:** every user-facing API result goes through `notify(...)`, which shows a snackbar and records the message in the bell's notification panel.
- **Diagnostics:** a rotating activity log is written to `<application support>/logs/activity.log`. It holds API calls (method, path, status, duration — never bodies, query strings or tokens), auth and sync events, and uncaught errors.

## Roles

| Area | Principal | Administrator | Accountant | Teaching staff |
|---|:-:|:-:|:-:|:-:|
| Dashboard, Reporting Center, Settings | ✓ | ✓ | ✓ | ✓ |
| Attendance, Students | ✓ | ✓ | | ✓ |
| Staff, Broadcasts | ✓ | ✓ | | |
| Academic Setup, Audit Logs | | ✓ | | |
| Finance | | | ✓ | |
| Results, Conduct | | | | ✓ |

Report visibility within the Reporting Center is set per report in `features/reports/data/report_catalogue.dart`.

## Contributing

- Branch from `master` and open a pull request back into it.
- Commit messages follow the repo convention: `#FIX:`, `#UPDATE:`, `#TEST:` or `#DOCS:`, then a short summary.
- Run `flutter analyze` and `flutter test` before pushing.
