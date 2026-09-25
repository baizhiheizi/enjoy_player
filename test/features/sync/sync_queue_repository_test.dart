import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/domain/sync_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SyncQueueRepository addOrUpsert refreshes existing composite row',
    () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);

      final id1 = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":1}',
      );
      await db.syncQueueDao.markAttempted(id1, error: 'fail');

      final id2 = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":2}',
      );
      expect(id2, id1);

      final row = await (db.select(
        db.syncQueue,
      )..where((t) => t.id.equals(id1))).getSingle();
      // Payload is refreshed; the retry / error state is preserved so
      // editing an entity does not silently re-arm a permanently
      // failed row.
      expect(row.payloadJson, '{"x":2}');
      expect(row.retryCount, 1);
      expect(row.error, 'fail');
    },
  );

  test(
    'SyncQueueRepository addOrUpsert preserves a permanently failed row',
    () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);
      final policy = SyncRetryPolicy();

      final id = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":1}',
      );
      for (var i = 0; i < policy.maxRetries; i++) {
        await db.syncQueueDao.markAttempted(id, error: 'fail $i');
      }

      final id2 = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":2}',
      );
      expect(id2, id);

      final row = await (db.select(
        db.syncQueue,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.payloadJson, '{"x":2}');
      expect(row.retryCount, policy.maxRetries);
      expect(row.error, 'fail 4');
    },
  );

  test(
    'SyncQueueRepository.resetFailed re-arms permanently failed rows',
    () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);
      final policy = SyncRetryPolicy();

      final id = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":1}',
      );
      for (var i = 0; i < policy.maxRetries; i++) {
        await db.syncQueueDao.markAttempted(id, error: 'fail');
      }

      final n = await repo.resetFailed();
      expect(n, 1);

      final row = await (db.select(
        db.syncQueue,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.retryCount, 0);
      expect(row.error, isNull);
      expect(row.lastAttempt, isNull);
    },
  );

  test('addOrUpsert is idempotent for the same composite key', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SyncQueueRepository(db);

    final id1 = await repo.addOrUpsert(
      entityType: 'audio',
      entityId: 'a1',
      action: 'create',
      payloadJson: '{"v":1}',
    );
    final id2 = await repo.addOrUpsert(
      entityType: 'audio',
      entityId: 'a1',
      action: 'create',
      payloadJson: '{"v":1}',
    );

    expect(id2, id1);
    final rows = await db.select(db.syncQueue).get();
    expect(rows, hasLength(1));
  });

  test('different actions on the same entity stay separate rows', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SyncQueueRepository(db);

    final createId = await repo.addOrUpsert(
      entityType: 'audio',
      entityId: 'a1',
      action: 'create',
      payloadJson: '{"v":1}',
    );
    final deleteId = await repo.addOrUpsert(
      entityType: 'audio',
      entityId: 'a1',
      action: 'delete',
    );

    expect(deleteId, isNot(createId));
    final rows = await db.select(db.syncQueue).get();
    expect(rows, hasLength(2));
  });

  test('per-user databases keep isolated sync queues', () async {
    final deviceGlobalDb = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(deviceGlobalDb.close);
    final userDb = AppDatabase(
      executor: NativeDatabase.memory(),
      name: 'enjoy_player_user-test',
    );
    addTearDown(userDb.close);

    final deviceGlobalRepo = SyncQueueRepository(deviceGlobalDb);
    final userRepo = SyncQueueRepository(userDb);

    await deviceGlobalRepo.addOrUpsert(
      entityType: 'audio',
      entityId: 'device-global-only',
      action: 'create',
      payloadJson: '{}',
    );
    await userRepo.addOrUpsert(
      entityType: 'audio',
      entityId: 'user-only',
      action: 'create',
      payloadJson: '{}',
    );

    expect(
      await deviceGlobalDb.select(deviceGlobalDb.syncQueue).get(),
      hasLength(1),
    );
    expect(await userDb.select(userDb.syncQueue).get(), hasLength(1));
    expect(deviceGlobalDb.isDeviceGlobalDatabase, isTrue);
    expect(userDb.isDeviceGlobalDatabase, isFalse);

    final deviceGlobalRow = await deviceGlobalDb
        .select(deviceGlobalDb.syncQueue)
        .getSingle();
    final userRow = await userDb.select(userDb.syncQueue).getSingle();
    expect(deviceGlobalRow.entityId, 'device-global-only');
    expect(userRow.entityId, 'user-only');
  });

  test('watchSnapshot counts retryable vs permanently failed rows', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SyncQueueRepository(db);

    final retryableId = await repo.addOrUpsert(
      entityType: 'audio',
      entityId: 'retry',
      action: 'create',
    );
    final failedId = await repo.addOrUpsert(
      entityType: 'audio',
      entityId: 'failed',
      action: 'create',
    );
    await db.syncQueueDao.markAttempted(retryableId, error: 'once');
    for (var i = 0; i < SyncRetryPolicy().maxRetries; i++) {
      await db.syncQueueDao.markAttempted(failedId, error: 'fail');
    }

    final snapshot = await repo.watchSnapshot().first;
    expect(snapshot.retryablePending, 1);
    expect(snapshot.permanentlyFailed, 1);
    expect(snapshot.isFullyCaughtUp, isFalse);
    expect(snapshot.detailRows, hasLength(2));
  });

  group('SyncQueueRepository concurrent addOrUpsert (issue #717 F4)', () {
    test('two concurrent addOrUpsert calls for the same composite key '
        'yield exactly one row', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);

      // Without the transaction wrapping the read+write in
      // addOrUpsert, both calls would observe "no row" and insert
      // duplicates. With the wrap, the SQLite executor serializes
      // them and the second call observes the first's insert.
      final results = await Future.wait([
        repo.addOrUpsert(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":1}',
        ),
        repo.addOrUpsert(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":2}',
        ),
      ]);

      // Same row id is returned to both callers.
      expect(results[0], equals(results[1]));
      final rows = await db.select(db.syncQueue).get();
      expect(rows, hasLength(1));
      // Last-writer-wins on payload (matches the single-threaded
      // addOrUpsert contract).
      expect(rows.single.payloadJson, anyOf('{"v":1}', '{"v":2}'));
    });

    test(
      'concurrent addOrUpsert for different composite keys stays separate',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final repo = SyncQueueRepository(db);

        await Future.wait([
          repo.addOrUpsert(
            entityType: 'video',
            entityId: 'vid-A',
            action: 'update',
            payloadJson: '{"v":"A"}',
          ),
          repo.addOrUpsert(
            entityType: 'video',
            entityId: 'vid-B',
            action: 'update',
            payloadJson: '{"v":"B"}',
          ),
          repo.addOrUpsert(
            entityType: 'video',
            entityId: 'vid-A',
            action: 'delete',
            payloadJson: null,
          ),
        ]);

        final rows = await db.select(db.syncQueue).get();
        expect(rows, hasLength(3));
        expect(rows.map((r) => '${r.entityId}/${r.action}').toSet(), {
          'vid-A/update',
          'vid-B/update',
          'vid-A/delete',
        });
      },
    );
  });

  group('SyncQueueRepository injected retry policy (issue #752)', () {
    test(
      'a non-default maxRetries drives every threshold-derived decision',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        // Distinctive non-default threshold: if any predicate or the DAO
        // write re-hardcodes the default 5, this test flips red.
        final repo = SyncQueueRepository(
          db,
          retryPolicy: SyncRetryPolicy(maxRetries: 2),
        );

        Future<int> row(String entityId) => repo.addOrUpsert(
          entityType: 'audio',
          entityId: entityId,
          action: 'create',
        );
        Future<int> retryCountOf(int id) async => (await (db.select(
          db.syncQueue,
        )..where((t) => t.id.equals(id))).getSingle()).retryCount;

        // Three rows: below the threshold (1 attempt), at the threshold
        // (2 attempts), and armed by markPermanentlyFailed.
        final belowId = await row('below');
        await repo.markAttempted(belowId, error: 'once');
        final atThresholdId = await row('at-threshold');
        await repo.markAttempted(atThresholdId, error: 'once');
        await repo.markAttempted(atThresholdId, error: 'twice');
        final armedId = await row('armed');
        await repo.markPermanentlyFailed(armedId, error: 'fatal');

        // markPermanentlyFailed writes exactly the injected threshold.
        expect(await retryCountOf(armedId), 2);

        // Only rows below the threshold stay pending; both threshold rows
        // count as permanently failed.
        expect((await repo.pendingItems()).map((r) => r.id), [belowId]);
        final snapshot = await repo.watchSnapshot().first;
        expect(snapshot.retryablePending, 1);
        expect(snapshot.permanentlyFailed, 2);

        // resetFailed re-arms ONLY the rows at the injected threshold —
        // the row below it keeps its retryCount, so the pin is on the
        // threshold, not on the updated-row count.
        expect(await repo.resetFailed(), 2);
        expect(await retryCountOf(belowId), 1);
        expect(await retryCountOf(atThresholdId), 0);
        expect(await retryCountOf(armedId), 0);
      },
    );
  });

  group('SyncQueueRepository.removeByIdIfPayload (issue #717 F3)', () {
    test('removes the row and returns it when the payload matches', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);

      final id = await repo.addOrUpsert(
        entityType: 'video',
        entityId: 'dQw4w9WgXcQ/en',
        action: 'update',
        payloadJson: '{"v":1}',
      );

      final removed = await repo.removeByIdIfPayload(id, '{"v":1}');
      expect(removed, isNotNull);
      expect(removed!.id, id);
      expect(removed.payloadJson, '{"v":1}');
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });

    test(
      'returns null and keeps the row when the payload has been refreshed',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final repo = SyncQueueRepository(db);

        final id = await repo.addOrUpsert(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":1}',
        );

        // Concurrent refresh — addOrUpsert overwrites payload only.
        await repo.addOrUpsert(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":2}',
        );

        // The older payload no longer matches — conditional remove must
        // leave the refreshed row in place so the next drain retries it.
        final removed = await repo.removeByIdIfPayload(id, '{"v":1}');
        expect(removed, isNull);
        final rows = await db.select(db.syncQueue).get();
        expect(rows, hasLength(1));
        expect(rows.single.payloadJson, '{"v":2}');
      },
    );

    test('returns null when the row is missing', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);

      final removed = await repo.removeByIdIfPayload(99999, '{"v":1}');
      expect(removed, isNull);
    });
  });
}
