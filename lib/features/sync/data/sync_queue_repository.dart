/// Persistence for the offline sync queue (Dexie-aligned).
library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;

import 'package:enjoy_player/core/utils/stream_combine_latest.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/domain/sync_queue_job.dart';
import 'package:enjoy_player/features/sync/domain/sync_retry_policy.dart';

/// Live counts + capped rows for sync status UI.
final class SyncQueueSnapshot {
  const SyncQueueSnapshot({
    required this.retryablePending,
    required this.permanentlyFailed,
    required this.detailRows,
  });

  /// Rows still eligible for retry — `retryCount` below
  /// [SyncRetryPolicy.maxRetries].
  final int retryablePending;

  /// Exhausted retries — `retryCount` at
  /// [SyncRetryPolicy.maxRetries].
  final int permanentlyFailed;

  /// Oldest-first subset for expandable UI (capped).
  final List<SyncQueueRow> detailRows;

  bool get isFullyCaughtUp => retryablePending == 0 && permanentlyFailed == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueSnapshot &&
          other.retryablePending == retryablePending &&
          other.permanentlyFailed == permanentlyFailed &&
          listEquals(other.detailRows, detailRows);

  @override
  int get hashCode => Object.hash(
    retryablePending,
    permanentlyFailed,
    Object.hashAll(detailRows),
  );
}

class SyncQueueRepository {
  /// [retryPolicy] supplies the threshold every predicate below derives
  /// from (issue #752); tests may inject one with a fake clock.
  SyncQueueRepository(this._db, {SyncRetryPolicy? retryPolicy})
    : _retryPolicy = retryPolicy ?? SyncRetryPolicy();

  final AppDatabase _db;

  /// Single source of the "permanently failed" threshold this repository's
  /// Drift predicates and the DAO `retryLimit` are written against.
  final SyncRetryPolicy _retryPolicy;

  /// Typed enqueue seam (issue #718): persists [job]'s wire columns with the
  /// same dedup / failed-state-preservation contract as [addOrUpsert].
  ///
  /// This is the only enqueue entry point feature code should use — the raw
  /// string API below exists for the sync feature internals (the drain's
  /// coalescing gate) and tests.
  Future<int> addJob(SyncQueueJob job) {
    final wire = job.encode();
    return addOrUpsert(
      entityType: wire.entityType,
      entityId: wire.entityId,
      action: wire.action,
      payloadJson: wire.payloadJson,
    );
  }

  /// Adds or refreshes a queue row for `(entityType, entityId, action)` —
  /// mirrors web [addSyncQueueItem].
  ///
  /// On an existing row, only [payloadJson] is overwritten. The
  /// `retryCount`, `lastAttempt`, and `error` columns are **preserved**
  /// so a permanently failed row stays failed even if the entity is
  /// edited locally — editing the entity should not silently re-arm
  /// a row that was rejected by the server. To re-arm failed rows
  /// use [resetFailed].
  ///
  /// The read+write pair runs inside a single Drift transaction so two
  /// concurrent enqueues for the same composite key cannot both observe
  /// "no row" and insert duplicates (issue #717 review followup). The
  /// earlier pre-#726 producer was insert-only; legacy installs may
  /// still carry those duplicates — the schema-version-18 migration in
  /// `AppDatabase._runMigrations` consolidates them so this `getSingleOrNull`
  /// never sees >1 row.
  ///
  /// Internal to the sync feature (issue #718): feature code must call
  /// [addJob] with a typed [SyncQueueJob] instead. The string API stays
  /// visible only because the seam test and the [addJob] shim need it.
  @visibleForTesting
  Future<int> addOrUpsert({
    required String entityType,
    required String entityId,
    required String action,
    String? payloadJson,
  }) => _db.transaction(() async {
    final q = _db.syncQueue;
    final existingId =
        await (_db.selectOnly(q)
              ..addColumns([q.id])
              ..where(
                q.entityType.equals(entityType) &
                    q.entityId.equals(entityId) &
                    q.action.equals(action),
              ))
            .map((row) => row.read(q.id)!)
            .getSingleOrNull();

    if (existingId != null) {
      await (_db.update(q)..where((t) => t.id.equals(existingId))).write(
        SyncQueueCompanion(payloadJson: Value(payloadJson)),
      );
      return existingId;
    }

    return _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            action: action,
            payloadJson: Value(payloadJson),
            createdAt: DateTime.now(),
          ),
        );
  });

  /// Rows that may still be retried — `retryCount` below
  /// [SyncRetryPolicy.maxRetries], oldest first.
  Future<List<SyncQueueRow>> pendingItems({int limit = 500}) {
    return (_db.select(_db.syncQueue)
          ..where((t) => _retryPolicy.eligible(t.retryCount))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Live aggregate counts (`retryablePending`, `permanentlyFailed`) without loading rows or payloads.
  Stream<({int retryablePending, int permanentlyFailed})> watchCounts() {
    final threshold = _retryPolicy.maxRetries;
    return _db
        .customSelect(
          'SELECT '
          'COALESCE(SUM(CASE WHEN retry_count < ? THEN 1 ELSE 0 END), 0) AS retryable, '
          'COALESCE(SUM(CASE WHEN retry_count >= ? THEN 1 ELSE 0 END), 0) AS failed '
          'FROM sync_queue',
          variables: [Variable.withInt(threshold), Variable.withInt(threshold)],
          readsFrom: {_db.syncQueue},
        )
        .watchSingle()
        .map(
          (row) => (
            retryablePending: row.read<int>('retryable'),
            permanentlyFailed: row.read<int>('failed'),
          ),
        )
        .distinct();
  }

  /// Watch queue for live status (counts + capped detail list without `payloadJson`).
  Stream<SyncQueueSnapshot> watchSnapshot({int detailLimit = 50}) {
    final q = _db.syncQueue;
    final detailStream =
        (_db.selectOnly(q)
              ..addColumns([
                q.id,
                q.entityType,
                q.entityId,
                q.action,
                q.retryCount,
                q.lastAttempt,
                q.error,
                q.createdAt,
              ])
              ..orderBy([OrderingTerm.asc(q.createdAt)])
              ..limit(detailLimit))
            .watch()
            .map(
              (rows) => [
                for (final row in rows)
                  SyncQueueRow(
                    id: row.read(q.id)!,
                    entityType: row.read(q.entityType)!,
                    entityId: row.read(q.entityId)!,
                    action: row.read(q.action)!,
                    payloadJson: null,
                    retryCount: row.read(q.retryCount)!,
                    lastAttempt: row.read(q.lastAttempt),
                    error: row.read(q.error),
                    createdAt: row.read(q.createdAt)!,
                  ),
              ],
            );
    return combineLatest2(
      watchCounts(),
      detailStream,
      (counts, detail) => SyncQueueSnapshot(
        retryablePending: counts.retryablePending,
        permanentlyFailed: counts.permanentlyFailed,
        detailRows: detail,
      ),
    ).distinct();
  }

  Future<void> removeById(int id) => _db.syncQueueDao.deleteId(id);

  /// Removes the row with [id] only if its stored `payload_json` still
  /// equals [expectedPayloadJson]. Returns the deleted row, or `null` when
  /// the row is missing or its payload has been refreshed since [item] was
  /// snapshotted (issue #717 review followup, race in `_processOne`).
  ///
  /// Used by `SyncYoutubeUploadRetry.processRetry` (and the decode-null
  /// drop path) so a successful upload of an older payload does not delete
  /// a newer payload that the producer wrote while the upload was in
  /// flight. Comparison is string equality — the retry path derives
  /// [expectedPayloadJson] from `job.encode().payloadJson`, whose encode
  /// stability contract (documented and tested on `SyncQueueJob.encode`,
  /// issue #749) guarantees a decode→encode round trip reproduces exactly
  /// the bytes the producer wrote; a different JSON string means a
  /// different timeline.
  Future<SyncQueueRow?> removeByIdIfPayload(
    int id,
    String expectedPayloadJson,
  ) => _db.transaction(() async {
    final row = await (_db.select(
      _db.syncQueue,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    if (row.payloadJson != expectedPayloadJson) return null;
    await _db.syncQueueDao.deleteId(id);
    return row;
  });

  Future<void> markAttempted(int id, {String? error}) =>
      _db.syncQueueDao.markAttempted(id, error: error);

  /// Marks the row permanently failed by writing the policy's
  /// [SyncRetryPolicy.maxRetries] as its `retryCount`, so it agrees with
  /// [pendingItems] / [watchSnapshot] / [resetFailed] by construction
  /// (issue #752).
  Future<void> markPermanentlyFailed(int id, {String? error}) =>
      _db.syncQueueDao.markPermanentlyFailed(
        id,
        retryLimit: _retryPolicy.maxRetries,
        error: error,
      );

  /// Clears error state for permanently failed items so they retry again.
  ///
  /// Single bulk UPDATE instead of SELECT+loop-UPDATE (issue #468).
  Future<int> resetFailed() async {
    final failed =
        await (_db.selectOnly(_db.syncQueue)
              ..addColumns([_db.syncQueue.id.count()])
              ..where(_retryPolicy.permanentlyFailed(_db.syncQueue.retryCount)))
            .map((row) => row.read<int>(_db.syncQueue.id.count()) ?? 0)
            .getSingle();
    if (failed == 0) return 0;
    await (_db.update(
      _db.syncQueue,
    )..where((t) => _retryPolicy.permanentlyFailed(t.retryCount))).write(
      const SyncQueueCompanion(
        retryCount: Value(0),
        error: Value(null),
        lastAttempt: Value(null),
      ),
    );
    return failed;
  }
}
