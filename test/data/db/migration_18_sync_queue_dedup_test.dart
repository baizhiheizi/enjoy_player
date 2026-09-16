/// Migration 18 test (issue #717 review followup, F5).
///
/// Pre-#726 the sync queue producer inserted a fresh row on every failed
/// upload, leaving installs with several rows for the same `(entity_type,
/// entity_id, action)`. The post-fix `SyncQueueRepository.addOrUpsert` does
/// `getSingleOrNull(...)` on that composite key, which throws when
/// duplicates exist; the producer's catch then silently drops the latest
/// retry payload. Migration 18 keeps the newest row per composite (highest
/// `id`, since the column is auto-increment and SQLite never reuses ids)
/// and deletes the rest, so the post-fix code path is sound on existing
/// databases.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migration 18 — sync queue dedup (issue #717 review F5)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is at least 18', () {
      expect(db.schemaVersion, greaterThanOrEqualTo(18));
    });

    test(
      'upgrade from v17 to v18 deduplicates legacy sync_queue rows',
      () async {
        final file = File(
          '${Directory.systemTemp.path}/'
          'migration_18_${DateTime.now().microsecondsSinceEpoch}.sqlite',
        );
        addTearDown(() {
          if (file.existsSync()) file.deleteSync();
        });

        // Seed a v17 schema with duplicate rows that pre-#726 would have
        // produced: every failed worker upload inserted a new row for the
        // same composite key.
        final seed = AppDatabase(executor: NativeDatabase(file));
        await seed.customStatement('PRAGMA user_version = 17');
        await seed.syncQueueDao.enqueue(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":1}',
        );
        await seed.syncQueueDao.enqueue(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":1}',
        );
        await seed.syncQueueDao.enqueue(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: '{"v":2}',
        );
        // An unrelated row that must survive untouched.
        await seed.syncQueueDao.enqueue(
          entityType: 'video',
          entityId: 'oQ4w9WgXcQ/fr',
          action: 'update',
          payloadJson: '{"v":"keep"}',
        );
        await seed.close();

        // Reopen → triggers onUpgrade(from: 17, to: 18).
        final reopened = AppDatabase(executor: NativeDatabase(file));
        addTearDown(reopened.close);
        await reopened.customSelect('SELECT 1').get();

        final remaining = await reopened.select(reopened.syncQueue).get();

        // Three duplicates collapsed to one; unrelated row untouched.
        expect(remaining, hasLength(2));
        final byEntity = {
          for (final r in remaining) '${r.entityId}/${r.action}': r,
        };
        expect(
          byEntity.keys,
          containsAll(['dQw4w9WgXcQ/en/update', 'oQ4w9WgXcQ/fr/update']),
        );

        // The kept row for the duplicated composite must be the newest
        // (highest id) — the latest payload the producer wrote.
        final kept = byEntity['dQw4w9WgXcQ/en/update']!;
        expect(kept.payloadJson, '{"v":2}');
      },
    );

    test(
      'upgrade from v17 to v18 is a no-op when no duplicates exist',
      () async {
        final file = File(
          '${Directory.systemTemp.path}/'
          'migration_18_clean_${DateTime.now().microsecondsSinceEpoch}.sqlite',
        );
        addTearDown(() {
          if (file.existsSync()) file.deleteSync();
        });

        final seed = AppDatabase(executor: NativeDatabase(file));
        await seed.customStatement('PRAGMA user_version = 17');
        await seed.syncQueueDao.enqueue(
          entityType: 'audio',
          entityId: 'aud-1',
          action: 'create',
        );
        await seed.syncQueueDao.enqueue(
          entityType: 'video',
          entityId: 'vid-1',
          action: 'delete',
        );
        await seed.close();

        final reopened = AppDatabase(executor: NativeDatabase(file));
        addTearDown(reopened.close);
        await reopened.customSelect('SELECT 1').get();

        final remaining = await reopened.select(reopened.syncQueue).get();
        expect(remaining, hasLength(2));
        expect(
          remaining.map((r) => '${r.entityType}:${r.entityId}:${r.action}'),
          containsAll(['audio:aud-1:create', 'video:vid-1:delete']),
        );
      },
    );
  });
}
