import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/application/rekey_local_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rekey rewrites placeholder audio id and aid for signed-in user', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    const userId = 'user-abc';
    const contentHash = 'deadbeef';
    final oldId = enjoyAudioId(aid: contentHash);
    final newAid = enjoyLocalAudioAid(
      contentHashHex: contentHash,
      userId: userId,
    );
    final newId = enjoyAudioId(aid: newAid);

    final now = DateTime.now();
    await db.audioDao.insertRow(
      AudioRow(
        id: oldId,
        aid: contentHash,
        provider: 'user',
        title: 'T',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 1,
        language: 'und',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///x.mp3',
        md5: contentHash,
        size: 100,
        mediaUrl: null,
        syncStatus: 'local-pending-rekey',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await rekeyLocalMediaRowsOnSignIn(db: db, userId: userId, enqueue: null);

    expect(await db.audioDao.getById(oldId), isNull);
    final row = await db.audioDao.getById(newId);
    expect(row, isNotNull);
    expect(row!.aid, newAid);
    expect(row.syncStatus, 'pending');
    expect(row.localUri, 'file:///x.mp3');
  });
}
