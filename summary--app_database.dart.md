<hash>size:7112</hash>

# `lib/data/db/app_database.dart`

- `AppDatabase` is Drift schema version 13 with 12 tables and focused DAO part files.
- Incremental migrations add Discover, transcript indexing, blur, AI cache, and subscription source/feed fields.
- `_addColumnIfMissing` makes column migrations retry-safe; `_runMigrations` no-ops when `from >= to`.
