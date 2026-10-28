# Local database recovery

What happens when the on-disk Drift/SQLite database is stale, malformed, or otherwise fails to open — and how the user recovers without reinstalling.

## Detection

`appPreferencesCtrlProvider` is the first provider to actually query the local database during bootstrap (`lib/app.dart`). If it fails, `EnjoyApp._errorMaterialApp` inspects the error with [`isUnrecoverableDatabaseError`](../../lib/core/recovery/recovery_actions.dart):

- `SqliteException`, `database is corrupt`, `database disk image is malformed`, `file is not a database`, `unable to open`
- `no such table`, `no such column`, `duplicate column name` (schema drift — e.g. an interrupted migration from a previous launch)
- `unsupported schema`

Matches route to [`RecoverySurface`](../../lib/core/recovery/recovery_surface.dart). Anything else falls back to a plain error screen (`Text('$error')`) — recovery UI is intentionally scoped to database problems, not every possible bootstrap failure.

`AppDatabase._runMigrations` (`lib/data/db/app_database.dart`) also defends against two DB-flow classes of bug so most stale/malformed states never reach the user at all:

- **Idempotent `addColumn`**: `_addColumnIfMissing` checks `pragma_table_info` before `ALTER TABLE ... ADD COLUMN`, so a migration step that partially ran on a previous crashed launch doesn't throw `duplicate column name` on every subsequent launch.
- **Downgrade no-op**: drift calls `onUpgrade` whenever `versionBefore != versionNow`, including when the on-disk version is *higher* than `schemaVersion` (e.g. a rolled-back release). `_runMigrations` returns immediately when `from >= to` instead of running upgrade steps against a newer/matching schema.

## Recovery surface

`RecoverySurface` and `WidgetErrorSurface` share `RecoveryErrorLayout` (SafeArea → 520 px column → scroll) and `RecoveryErrorPanel` (error icon, title, subtitle, mono error card, copy action) from `lib/core/recovery/recovery_error_panel.dart`; only the shell (`Scaffold` vs `Material`) and the surface-specific extra actions differ.

Full-screen, localized (`AppLocalizations`) UI offering:

- **Copy error** — error + stack trace to clipboard, for support handoff.
- **Open logs folder** — reveals the rotating log directory in the OS file manager (desktop only; always fails gracefully on mobile, which has no such API).
- **Reset local library** — destructive action behind a confirmation dialog.

Because this surface can render *before* `appPreferencesCtrlProvider` resolves a locale, `_loadingMaterialApp` / `_errorMaterialApp` carry their own `localizationsDelegates` / `supportedLocales` (`_fallbackLocalizationsDelegates`) instead of relying on the router-backed `MaterialApp.router` that only exists once prefs load successfully.

## Reset flow

1. [`backupLocalDatabaseFile`](../../lib/core/recovery/recovery_actions.dart) best-effort copies the guest `.sqlite` file to `{applicationSupport}/migrations/enjoy_player_<timestamp>.sqlite`.
   - Drift's `drift_flutter` package stores `.sqlite` files directly under `getApplicationDocumentsDirectory()` (not `ApplicationSupport/databases/`) — recovery code must read from the same place drift writes to.
2. If the backup succeeds, [`wipeLocalDatabaseFiles`](../../lib/core/recovery/recovery_actions.dart) deletes the device-global DB (`.sqlite`, `-wal`, `-shm`) plus any other `.sqlite*` files found in that directory (covers per-user DBs from a previously signed-in session).
3. `performRecoveryReset` (`lib/app.dart`) — the Riverpod-aware wrapper wired into `RecoverySurface.onReset` — closes the currently-open `AppDatabase` connection first (some platforms refuse to delete a memory-mapped file), then on success invalidates `deviceGlobalAppDatabaseProvider`, `appDatabaseProvider`, and `appPreferencesCtrlProvider` so the app **reloads in place** instead of leaving the user stuck on the recovery screen until they manually relaunch.
4. Outcome (`RecoveryResetOutcome.success` / `backupFailed` / `wipeFailed`) drives a toast (`recoveryResetLibrarySuccess` / `recoveryResetLibraryBackupError` / `recoveryResetLibraryError` in `lib/l10n/*.arb`).

`performRecoveryReset` takes a Riverpod `Ref`, not a `WidgetRef`/`ProviderContainer` (neither implements `Ref`). Both production (`_errorMaterialApp`, via `WidgetRef`) and tests (via a plain `ProviderContainer`) reach it through the same `recoveryResetResultProvider` `FutureProvider`, which supplies a real `Ref` internally — `ref.invalidate(recoveryResetResultProvider)` then `ref.read(recoveryResetResultProvider.future)`.

The auth/session token is untouched by a reset — a signed-in user keeps their session in secure storage and simply rebuilds an empty per-user database on next read.

## Tests

- `test/data/db/app_database_test.dart` — idempotent-migration and downgrade-no-op regressions.
- `test/core/recovery/recovery_actions_test.dart` — backup/wipe directory correctness, `isUnrecoverableDatabaseError` patterns.
- `test/core/recovery/recovery_surface_test.dart` — widget-level `onReset` wiring.
- `test/app_recovery_flow_test.dart` — end-to-end: `EnjoyApp` renders a localized `RecoverySurface` on a real provider failure; `performRecoveryReset` is exercised against a real `ProviderContainer` with real `dart:io` (split out of `testWidgets` because real file I/O doesn't resolve inside its fake-async zone).
