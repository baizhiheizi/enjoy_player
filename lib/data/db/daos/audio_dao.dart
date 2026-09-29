part of '../app_database.dart';

@DriftAccessor(tables: [Audios])
class AudioDao extends DatabaseAccessor<AppDatabase> with _$AudioDaoMixin {
  AudioDao(super.db);

  Stream<List<AudioRow>> watchAll() => (select(
    audios,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<AudioRow?> getById(String id) =>
      (select(audios)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Bulk-fetch rows by primary key in one `WHERE id IN (…)` query (issue
  /// #810 D3 — replaces a per-id `getById` round trip per server row in the
  /// sync download loop). Missing ids are absent from the map.
  Future<Map<String, AudioRow>> getManyByIds(Iterable<String> ids) async {
    final values = ids.toList();
    if (values.isEmpty) return const {};
    final rows = await (select(audios)..where((t) => t.id.isIn(values))).get();
    return {for (final row in rows) row.id: row};
  }

  Future<AudioRow?> getByMd5(String md5) =>
      (select(audios)..where((t) => t.md5.equals(md5))).getSingleOrNull();

  Future<void> insertRow(AudioRow row) =>
      into(audios).insert(row, mode: InsertMode.insertOrReplace);

  /// Batch upsert sharing [insertRow]'s semantics in one Drift `batch`
  /// (single transaction + COMMIT). Empty input is a no-op.
  Future<void> upsertRows(List<AudioRow> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(audios, rows, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> updateLanguage({
    required String id,
    required String language,
  }) async {
    await (update(audios)..where((t) => t.id.equals(id))).write(
      AudiosCompanion(
        language: Value(language),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Bumps [Audios.updatedAt] so Home "Recent media" can resurface the row.
  Future<void> touchUpdatedAt(String id) async {
    await (update(audios)..where((t) => t.id.equals(id))).write(
      AudiosCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  /// Conditionally writes [durationSeconds] (bumping `updatedAt`) **only when
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
          audios,
        )..where((t) => t.id.equals(id) & t.durationSeconds.equals(0))).write(
          AudiosCompanion(
            durationSeconds: Value(durationSeconds),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return affected == 1;
  }

  Future<void> deleteId(String id) =>
      (delete(audios)..where((t) => t.id.equals(id))).go();

  /// Whether any row's [Audios.localUri] equals [localUri] (exact match).
  ///
  /// Uses `SELECT 1 … LIMIT 1` (EXISTS) instead of materialising full rows
  /// just to count them — paired with the `idx_audios_local_uri` index added
  /// in migration 16 (issue #469).
  Future<bool> existsByLocalUri(String localUri) async {
    final row =
        await (selectOnly(audios)
              ..addColumns([audios.id])
              ..where(audios.localUri.equals(localUri))
              ..limit(1))
            .map((r) => r.read(audios.id))
            .getSingleOrNull();
    return row != null;
  }
}
