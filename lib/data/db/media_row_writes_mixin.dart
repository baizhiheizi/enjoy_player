/// Shared single-row writes for the `videos` / `audios` DAO pair (issue #1042).
///
/// Hand-written (not a `part of` the database library, no `@DriftAccessor`),
/// so applying it to existing DAOs requires no codegen regeneration.
library;

import 'package:drift/drift.dart';

/// Provides the single-row read/write methods the two media DAOs share.
///
/// Implementations supply only [mediaRowTable]; the primary key and the
/// `local_uri` / `duration_seconds` columns resolve through Drift's
/// `columnsByName` at first use, so a column renamed on one table fails loudly
/// here instead of silently diverging between the two DAOs.
mixin MediaRowWritesMixin<DB extends GeneratedDatabase, R extends Insertable<R>>
    on DatabaseAccessor<DB> {
  /// Table read and written by every method in this mixin.
  TableInfo<Table, R> get mediaRowTable;

  /// Primary key of [mediaRowTable].
  late final GeneratedColumn<String> mediaRowId =
      mediaRowTable.$primaryKey.single as GeneratedColumn<String>;

  late final GeneratedColumn<String> _localUri =
      mediaRowTable.columnsByName['local_uri']! as GeneratedColumn<String>;

  late final GeneratedColumn<int> _durationSeconds =
      mediaRowTable.columnsByName['duration_seconds']! as GeneratedColumn<int>;

  Future<R?> getById(String id) => (select(
    mediaRowTable,
  )..where((_) => mediaRowId.equals(id))).getSingleOrNull();

  Future<void> insertRow(R row) =>
      into(mediaRowTable).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> updateLanguage({required String id, required String language}) =>
      _write(id, {'language': Variable<String>(language)});

  Future<void> updateTitle({required String id, required String title}) =>
      _write(id, {'title': Variable<String>(title)});

  /// Bumps `updated_at` so Home "Recent media" can resurface the row.
  Future<void> touchUpdatedAt(String id) =>
      _write(id, const <String, Expression>{});

  /// Conditionally writes [durationSeconds] (bumping `updated_at`) **only when
  /// the stored value is still zero** — the WHERE guard makes the operation
  /// race-free: a concurrent backfill that landed first is no longer
  /// overwritten by a stale probe, and an unrelated field change between the
  /// caller's read and this write is preserved (we touch `duration_seconds`
  /// and `updated_at` only).
  ///
  /// Returns `true` when one row was patched, `false` when no row matched
  /// (unknown id) **or** the row already had a non-zero duration.
  Future<bool> setDurationIfZero(String id, int durationSeconds) async {
    final affected =
        await (update(
              mediaRowTable,
            )..where((_) => mediaRowId.equals(id) & _durationSeconds.equals(0)))
            .write(
              RawValuesInsertable({
                'duration_seconds': Variable<int>(durationSeconds),
                'updated_at': Variable<DateTime>(DateTime.now()),
              }),
            );
    return affected == 1;
  }

  Future<void> deleteId(String id) =>
      (delete(mediaRowTable)..where((_) => mediaRowId.equals(id))).go();

  /// Whether any row's `local_uri` equals [localUri] (exact match).
  ///
  /// Uses `SELECT 1 … LIMIT 1` (EXISTS) instead of materialising full rows
  /// just to count them — paired with the per-table `idx_*_local_uri` index
  /// added in migration 16 (issue #469).
  Future<bool> existsByLocalUri(String localUri) async {
    final row =
        await (selectOnly(mediaRowTable)
              ..addColumns([mediaRowId])
              ..where(_localUri.equals(localUri))
              ..limit(1))
            .map((r) => r.read(mediaRowId))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> _write(String id, Map<String, Expression> fields) async {
    await (update(mediaRowTable)..where((_) => mediaRowId.equals(id))).write(
      RawValuesInsertable({
        ...fields,
        'updated_at': Variable<DateTime>(DateTime.now()),
      }),
    );
  }
}
