import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncDuplicateMissingError describes entity and id', () {
    final err = SyncDuplicateMissingError('video', 'vid-1');
    expect(err.toString(), contains('video'));
    expect(err.toString(), contains('vid-1'));
    expect(err.toString(), contains('404'));
  });

  test('markPermanentlyFailed sets retryCount to 5', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SyncQueueRepository(db);

    final id = await repo.addOrUpsert(
      entityType: 'video',
      entityId: 'v1',
      action: 'create',
      payloadJson: '{}',
    );

    await repo.markPermanentlyFailed(id, error: 'duplicate missing');

    final row = await (db.select(
      db.syncQueue,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(row.retryCount, 5);
    expect(row.error, 'duplicate missing');
    expect(shouldRetryQueueItem(row), isFalse);
  });
}
