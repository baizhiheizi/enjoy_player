import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
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

      final id = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":1}',
      );
      for (var i = 0; i < 5; i++) {
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
      expect(row.retryCount, 5);
      expect(row.error, 'fail 4');
    },
  );

  test(
    'SyncQueueRepository.resetFailed re-arms permanently failed rows',
    () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SyncQueueRepository(db);

      final id = await repo.addOrUpsert(
        entityType: 'audio',
        entityId: 'a1',
        action: 'create',
        payloadJson: '{"x":1}',
      );
      for (var i = 0; i < 5; i++) {
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
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final guestDb = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(guestDb.close);
    final userDb = AppDatabase(
      executor: NativeDatabase.memory(),
      name: 'enjoy_player_user-test',
    );
    addTearDown(userDb.close);

    final guestRepo = SyncQueueRepository(guestDb);
    final userRepo = SyncQueueRepository(userDb);

    await guestRepo.addOrUpsert(
      entityType: 'audio',
      entityId: 'guest-only',
      action: 'create',
      payloadJson: '{}',
    );
    await userRepo.addOrUpsert(
      entityType: 'audio',
      entityId: 'user-only',
      action: 'create',
      payloadJson: '{}',
    );

    expect(await guestDb.select(guestDb.syncQueue).get(), hasLength(1));
    expect(await userDb.select(userDb.syncQueue).get(), hasLength(1));
    expect(guestDb.isGuestDatabase, isTrue);
    expect(userDb.isGuestDatabase, isFalse);

    final guestRow = await guestDb.select(guestDb.syncQueue).getSingle();
    final userRow = await userDb.select(userDb.syncQueue).getSingle();
    expect(guestRow.entityId, 'guest-only');
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
    for (var i = 0; i < 5; i++) {
      await db.syncQueueDao.markAttempted(failedId, error: 'fail');
    }

    final snapshot = await repo.watchSnapshot().first;
    expect(snapshot.retryablePending, 1);
    expect(snapshot.permanentlyFailed, 1);
    expect(snapshot.isFullyCaughtUp, isFalse);
    expect(snapshot.detailRows, hasLength(2));
  });
}
