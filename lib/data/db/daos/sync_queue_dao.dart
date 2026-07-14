part of '../app_database.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> enqueue({
    required String entityType,
    required String entityId,
    required String action,
    String? payloadJson,
  }) => into(syncQueue).insert(
    SyncQueueCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      action: action,
      payloadJson: Value(payloadJson),
      createdAt: DateTime.now(),
    ),
  );

  Future<List<SyncQueueRow>> peekBatch({int limit = 50}) =>
      (select(syncQueue)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<void> markAttempted(int id, {String? error}) async {
    final existing = await (select(
      syncQueue,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(existing.retryCount + 1),
        lastAttempt: Value(DateTime.now()),
        error: Value(error),
      ),
    );
  }

  Future<void> deleteId(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();
}
