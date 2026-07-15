<hash>size:8547</hash>

# `lib/core/recovery/recovery_actions.dart`

- Copies bootstrap diagnostics, opens the desktop log directory, backs up local databases, and wipes SQLite/WAL/SHM files.
- Database files are resolved from the directory used by `drift_flutter`.
- `isUnrecoverableDatabaseError` recognizes SQLite exceptions, corruption, unsupported schema, and missing/duplicate schema objects.
