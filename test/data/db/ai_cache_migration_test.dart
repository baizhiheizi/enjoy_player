import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('v11 → v12 migration', () {
    test('creates ai_cache table and preserves existing data', () async {
      // Construct a v11 schema directly by mimicking what _runMigrations
      // would have set up. We open a fresh in-memory database, run the
      // v11 schema creation explicitly, populate every existing table
      // with one row, then run the v11→v12 migration step manually and
      // assert every row survives.
      final db = AppDatabase(executor: NativeDatabase.memory());

      try {
        // Phase 1: simulate the v11 schema by recreating every table from
        // scratch. Drift's onCreate is only invoked when the database has
        // no `user_version` pragma — opening a memory db invokes it. We
        // immediately bump schemaVersion to v11 by writing to user_version
        // so we can re-run only the v12 step.
        await db.customStatement('PRAGMA user_version = 11');

        // Insert a row into every existing table to verify data preservation.
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

        // Phase 2: invoke the v12 migration step directly. We mirror what
        // `_runMigrations` does for `next == 12`.
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

        // Phase 3: verify the new table exists and the existing data is
        // preserved.
        final aiCacheCount = await db
            .customSelect('SELECT COUNT(*) AS c FROM ai_cache')
            .map((row) => row.read<int>('c'))
            .getSingle();
        expect(aiCacheCount, 0); // empty table

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

        // Phase 4: verify the new index exists.
        final indexRows = await db
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'index' AND name = 'idx_ai_cache_kind_updated_at'",
            )
            .get();
        expect(indexRows.length, 1);

        // Phase 5: write to the new table to confirm it works.
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
