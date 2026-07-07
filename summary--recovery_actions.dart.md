<size>7132</size>

# `lib/core/recovery/recovery_actions.dart`

- `Future<bool> copyErrorToClipboard(Object error, StackTrace? stack)` — best-effort copy of error + stack to clipboard.
- `Future<bool> openLogsFolder()` — opens the rotating log directory in the platform file explorer (returns false on mobile).
- Looks for DB files in the `Documents` directory (where `drift_flutter` writes them), NOT `ApplicationSupport/databases/`.
- Broadens `isUnrecoverableDatabaseError` to catch `SqliteException`, `no such column`, `duplicate column name`, `disk image malformed`.
