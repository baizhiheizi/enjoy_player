/// Persistence for the offline sync queue (Dexie-aligned).
library;

import 'package:drift/drift.dart';

import 'package:enjoy_player/data/db/app_database.dart';

class SyncQueueRepository {
  SyncQueueRepository(this._db);

  final AppDatabase _db;

  /// Adds or refreshes a queue row for `(entityType, entityId, action)` —
  /// mirrors web [addSyncQueueItem].
  Future<int> addOrUpsert({
    required String entityType,
    required String entityId,
    required String action,
    String? payloadJson,
  }) async {
    final existing = await (_db.select(_db.syncQueue)
          ..where(
            (t) =>
                t.entityType.equals(entityType) &
                t.entityId.equals(entityId) &
                t.action.equals(action),
          ))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(existing.id)))
          .write(
        SyncQueueCompanion(
          payloadJson: Value(payloadJson),
          retryCount: const Value(0),
          error: const Value(null),
          lastAttempt: const Value(null),
        ),
      );
      return existing.id;
    }

    return _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            action: action,
            payloadJson: Value(payloadJson),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Rows that may still be retried (`retryCount < 5`), oldest first.
  Future<List<SyncQueueRow>> pendingItems({int limit = 500}) {
    return (_db.select(_db.syncQueue)
          ..where((t) => t.retryCount.isSmallerThanValue(5))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> removeById(int id) => _db.syncQueueDao.deleteId(id);

  Future<void> markAttempted(int id, {String? error}) =>
      _db.syncQueueDao.markAttempted(id, error: error);

  /// Clears error state for permanently failed items so they retry again.
  Future<int> resetFailed() async {
    final failed = await (_db.select(_db.syncQueue)
          ..where((t) => t.retryCount.isBiggerOrEqualValue(5)))
        .get();

    for (final item in failed) {
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
          .write(
        const SyncQueueCompanion(
          retryCount: Value(0),
          error: Value(null),
          lastAttempt: Value(null),
        ),
      );
    }
    return failed.length;
  }
}
