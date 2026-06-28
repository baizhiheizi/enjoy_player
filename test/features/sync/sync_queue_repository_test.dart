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
      // Drive the row to permanent failure (5 failed attempts).
      for (var i = 0; i < 5; i++) {
        await db.syncQueueDao.markAttempted(id, error: 'fail $i');
      }

      // Editing the entity updates the payload but does NOT reset the
      // retry budget.
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
}
