part of '../app_database.dart';

@DriftAccessor(tables: [Recordings])
class RecordingDao extends DatabaseAccessor<AppDatabase>
    with _$RecordingDaoMixin {
  RecordingDao(super.db);

  Stream<List<RecordingRow>> watchByTarget(
    String targetType,
    String targetId,
  ) =>
      (select(recordings)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .distinctBy(listEquals);

  Stream<List<RecordingRow>> watchByEchoRegion({
    required String targetType,
    required String targetId,
    required String language,
    required int echoStartMs,
    required int echoEndMs,
  }) =>
      (select(recordings)
            ..where((t) {
              final recordingEnd = t.referenceStart + t.referenceDuration;
              return t.targetType.equals(targetType) &
                  t.targetId.equals(targetId) &
                  t.language.equals(language) &
                  t.referenceStart.isSmallerThanValue(echoEndMs) &
                  recordingEnd.isBiggerThanValue(echoStartMs);
            })
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .distinctBy(listEquals);

  Future<List<RecordingRow>> listByEchoRegion({
    required String targetType,
    required String targetId,
    required String language,
    required int echoStartMs,
    required int echoEndMs,
  }) async {
    return (select(recordings)
          ..where((t) {
            final recordingEnd = t.referenceStart + t.referenceDuration;
            return t.targetType.equals(targetType) &
                t.targetId.equals(targetId) &
                t.language.equals(language) &
                t.referenceStart.isSmallerThanValue(echoEndMs) &
                recordingEnd.isBiggerThanValue(echoStartMs);
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<RecordingRow?> getById(String id) =>
      (select(recordings)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Bulk-fetch rows by primary key in one `WHERE id IN (…)` query (issue
  /// #810 D3 — replaces a per-id `getById` round trip per server row in the
  /// sync download loop). Missing ids are absent from the map.
  Future<Map<String, RecordingRow>> getManyByIds(Iterable<String> ids) async {
    final values = ids.toList();
    if (values.isEmpty) return const {};
    final rows = await (select(
      recordings,
    )..where((t) => t.id.isIn(values))).get();
    return {for (final row in rows) row.id: row};
  }

  Future<void> insertRow(RecordingRow row) =>
      into(recordings).insert(row, mode: InsertMode.insertOrReplace);

  /// Batch upsert sharing [insertRow]'s semantics in one Drift `batch`
  /// (single transaction + COMMIT). Empty input is a no-op.
  Future<void> upsertRows(List<RecordingRow> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(recordings, rows, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> updateAssessment({
    required String id,
    required int? pronunciationScore,
    required String? assessmentJson,
    required DateTime updatedAt,
  }) => (update(recordings)..where((t) => t.id.equals(id))).write(
    RecordingsCompanion(
      pronunciationScore: Value(pronunciationScore),
      assessmentJson: Value(assessmentJson),
      updatedAt: Value(updatedAt),
      syncStatus: const Value('local'),
    ),
  );

  Future<void> deleteId(String id) =>
      (delete(recordings)..where((t) => t.id.equals(id))).go();
}
