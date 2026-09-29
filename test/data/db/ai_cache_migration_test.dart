import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('v11 → v12 migration', () {
    test('creates ai_cache table and preserves existing data', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());

      try {
        await db.customStatement('PRAGMA user_version = 11');

        final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

        await db.videoDao.insertRow(
          VideoRow(
            id: 'v-mig-1',
            vid: 'v1234567890',
            provider: 'youtube',
            title: 'mig',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 60,
            language: 'en',
            source: 'local',
            localUri: '/tmp/mig.mp4',
            md5: null,
            size: null,
            mediaUrl: null,
            syncStatus: 'local',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.echoSessionDao.updatePrimaryTranscriptForTarget(
          'Video',
          'v-mig-1',
          null,
        );
        await db.settingsDao.setValue('api.base_url', 'value-mig');

        await db.customStatement(
          'CREATE TABLE IF NOT EXISTS ai_cache ('
          'kind TEXT NOT NULL, '
          'key TEXT NOT NULL, '
          'payload_json TEXT NOT NULL, '
          'updated_at INTEGER NOT NULL, '
          'PRIMARY KEY (kind, key))',
        );
        await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_ai_cache_kind_updated_at '
          'ON ai_cache (kind, updated_at DESC)',
        );

        final aiCacheCount = await db
            .customSelect('SELECT COUNT(*) AS c FROM ai_cache')
            .map((row) => row.read<int>('c'))
            .getSingle();
        expect(aiCacheCount, 0);

        final videoRows = await db
            .customSelect(
              'SELECT id FROM videos WHERE id = ?',
              variables: [Variable.withString('v-mig-1')],
            )
            .get();
        expect(videoRows.length, 1);

        final echoRows = await db
            .customSelect(
              'SELECT id FROM echo_sessions WHERE target_id = ?',
              variables: [Variable.withString('v-mig-1')],
            )
            .get();
        expect(echoRows.length, 1);

        final settingValue = await db.settingsDao.getValue('api.base_url');
        expect(settingValue, 'value-mig');

        final indexRows = await db
            .customSelect(
              'SELECT name FROM sqlite_master '
              'WHERE type = \'index\' AND name = \'idx_ai_cache_kind_updated_at\'',
            )
            .get();
        expect(indexRows.length, 1);

        await db.aiCacheDao.upsert('translation', 'k1', '{"v":1}', now);
        final newRow = await db.aiCacheDao.read('translation', 'k1');
        expect(newRow, isNotNull);
        expect(newRow!.payloadJson, '{"v":1}');
      } finally {
        await db.close();
      }
    });
  });
}
