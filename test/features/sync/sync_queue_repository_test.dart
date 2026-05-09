import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncQueueRepository addOrUpsert refreshes existing composite row', () async {
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

    final row =
        await (db.select(db.syncQueue)..where((t) => t.id.equals(id1))).getSingle();
    expect(row.retryCount, 0);
    expect(row.error, isNull);
    expect(row.payloadJson, '{"x":2}');
  });
}
