part of '../app_database.dart';

@DriftAccessor(tables: [TranscriptFetchStates])
class TranscriptFetchStateDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptFetchStateDaoMixin {
  TranscriptFetchStateDao(super.db);

  Future<TranscriptFetchStateRow?> getForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcriptFetchStates)..where(
            (t) =>
                t.targetType.equals(targetType) & t.targetId.equals(targetId),
          ))
          .getSingleOrNull();

  Future<void> upsertFetched(
    String targetType,
    String targetId,
    DateTime lastFetchedAt, {
    String? lastStatus,
    String? lastError,
  }) => upsertOutcome(
    targetType: targetType,
    targetId: targetId,
    lastFetchedAt: lastFetchedAt,
    lastStatus: lastStatus ?? 'success',
    lastError: lastError,
  );

  Future<void> upsertOutcome({
    required String targetType,
    required String targetId,
    required DateTime lastFetchedAt,
    required String lastStatus,
    String? lastError,
  }) => into(transcriptFetchStates).insert(
    TranscriptFetchStateRow(
      targetType: targetType,
      targetId: targetId,
      lastFetchedAt: lastFetchedAt,
      lastStatus: lastStatus,
      lastError: lastError,
    ),
    mode: InsertMode.insertOrReplace,
  );

  Future<void> clearForTarget(String targetType, String targetId) async {
    await (delete(transcriptFetchStates)..where(
          (t) => t.targetType.equals(targetType) & t.targetId.equals(targetId),
        ))
        .go();
  }
}
