part of '../app_database.dart';

/// Light read-model for [TranscriptDao.watchSummariesForTarget]: track
/// metadata plus the change-tick columns, never `timeline_json` (issue
/// #810 D2 — watching full rows re-copied every timeline blob to the UI
/// isolate on each write).
final class TranscriptTrackSummary {
  const TranscriptTrackSummary({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.source,
    required this.label,
    required this.trackIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String language;
  final String source;
  final String label;
  final int? trackIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
}

@DriftAccessor(tables: [Transcripts])
class TranscriptDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptDaoMixin {
  TranscriptDao(super.db);

  Stream<List<TranscriptTrackSummary>> watchSummariesForTarget(
    String targetType,
    String targetId,
  ) {
    final query = selectOnly(transcripts)
      ..addColumns([
        transcripts.id,
        transcripts.targetType,
        transcripts.targetId,
        transcripts.language,
        transcripts.source,
        transcripts.label,
        transcripts.trackIndex,
        transcripts.createdAt,
        transcripts.updatedAt,
      ])
      ..where(
        transcripts.targetType.equals(targetType) &
            transcripts.targetId.equals(targetId),
      )
      ..orderBy([
        OrderingTerm.asc(transcripts.source),
        OrderingTerm.asc(transcripts.language),
        OrderingTerm.asc(transcripts.createdAt),
      ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          TranscriptTrackSummary(
            id: row.read<String>(transcripts.id)!,
            targetType: row.read<String>(transcripts.targetType)!,
            targetId: row.read<String>(transcripts.targetId)!,
            language: row.read<String>(transcripts.language)!,
            source: row.read<String>(transcripts.source)!,
            label: row.read<String>(transcripts.label)!,
            trackIndex: row.read<int>(transcripts.trackIndex),
            createdAt: row.read<DateTime>(transcripts.createdAt)!,
            updatedAt: row.read<DateTime>(transcripts.updatedAt)!,
          ),
      ],
    );
  }

  Stream<bool> watchExistsForTarget(String targetType, String targetId) {
    return customSelect(
      'SELECT EXISTS (SELECT 1 FROM transcripts WHERE target_type = ? AND target_id = ?) AS e',
      variables: [
        Variable.withString(targetType),
        Variable.withString(targetId),
      ],
      readsFrom: {transcripts},
    ).watch().map((rows) => rows.first.read<int>('e') != 0);
  }

  Future<TranscriptRow?> getById(String id) =>
      (select(transcripts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TranscriptRow>> listForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)..where(
            (t) =>
                t.targetType.equals(targetType) & t.targetId.equals(targetId),
          ))
          .get();

  Future<void> upsert(TranscriptRow row) =>
      into(transcripts).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(transcripts)..where((t) => t.id.equals(id))).go();
}
