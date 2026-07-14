part of '../app_database.dart';

@DriftAccessor(tables: [Transcripts])
class TranscriptDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptDaoMixin {
  TranscriptDao(super.db);

  Stream<List<TranscriptRow>> watchForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.language)]))
          .watch();

  Stream<List<TranscriptRow>> watchAllForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.source),
              (t) => OrderingTerm.asc(t.language),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

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
