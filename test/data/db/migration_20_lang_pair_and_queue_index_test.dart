/// Migration 20 test (issue #827 C3+C4): `sync_queue (created_at)` index
/// backing `peekBatch`'s `ORDER BY created_at`, plus `ai_cache` language
/// pair columns + `idx_ai_cache_lang_pair` + payload backfill replacing
/// `evictForPair`'s leading-wildcard `payload_json LIKE` scan.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migration 20 — sync queue index + ai cache pair columns', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is at least 20', () {
      expect(db.schemaVersion, greaterThanOrEqualTo(20));
    });

    test(
      'fresh install serves peekBatch and deleteForPair from indexes',
      () async {
        final queuePlan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN '
              'SELECT id FROM sync_queue ORDER BY created_at ASC LIMIT 50',
            )
            .get();
        expect(
          queuePlan.map((row) => row.read<String>('detail')).join('\n'),
          contains('idx_sync_queue_created_at'),
        );

        final pairPlan = await db
            .customSelect(
              'EXPLAIN QUERY PLAN '
              'SELECT key FROM ai_cache '
              'WHERE source_language = ? AND target_language = ?',
              variables: [Variable.withString('en'), Variable.withString('es')],
            )
            .get();
        expect(
          pairPlan.map((row) => row.read<String>('detail')).join('\n'),
          contains('idx_ai_cache_lang_pair'),
        );
      },
    );

    test('upgrade from v19 creates the sync_queue index', () async {
      final file = File(
        '${Directory.systemTemp.path}/'
        'migration_20_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final seed = AppDatabase(executor: NativeDatabase(file));
      await seed.customStatement('PRAGMA user_version = 19');
      await seed.close();

      final reopened = AppDatabase(executor: NativeDatabase(file));
      addTearDown(reopened.close);
      await reopened.customSelect('SELECT 1').get();

      final indexes = await reopened
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_sync_queue_created_at'",
          )
          .get();
      expect(indexes, hasLength(1));
    });

    test(
      'upgrade from v19 backfills ai_cache pairs and evicts by column',
      () async {
        final file = File(
          '${Directory.systemTemp.path}/'
          'migration_20_${DateTime.now().microsecondsSinceEpoch}.sqlite',
        );
        addTearDown(() {
          if (file.existsSync()) file.deleteSync();
        });

        final seed = AppDatabase(executor: NativeDatabase(file));
        await seed.customStatement('PRAGMA user_version = 19');
        await seed.customStatement(
          'INSERT INTO ai_cache (kind, key, payload_json, updated_at) VALUES '
          "('translation', 'paired', "
          "'{\"v\":\"x\",\"sourceLanguage\":\"en\",\"targetLanguage\":\"es\"}', 1), "
          "('translation', 'pairless', '{\"v\":\"y\"}', 2), "
          "('translation', 'malformed', 'not-json{', 4), "
          "('translation', 'other', "
          "'{\"v\":\"z\",\"sourceLanguage\":\"en\",\"targetLanguage\":\"ja\"}', 3)",
        );
        await seed.close();

        final reopened = AppDatabase(executor: NativeDatabase(file));
        addTearDown(reopened.close);
        await reopened.customSelect('SELECT 1').get();

        final rows = await reopened
            .customSelect(
              'SELECT key, source_language, target_language FROM ai_cache '
              'ORDER BY key',
            )
            .get();
        final byKey = {
          for (final row in rows)
            row.read<String>('key'): (
              src: row.readNullable<String>('source_language'),
              tgt: row.readNullable<String>('target_language'),
            ),
        };
        expect(byKey['paired'], (src: 'en', tgt: 'es'));
        expect(byKey['other'], (src: 'en', tgt: 'ja'));
        expect(byKey['pairless'], (src: null, tgt: null));
        expect(byKey['malformed'], (src: null, tgt: null));

        final deleted = await reopened.aiCacheDao.deleteForPair('en', 'es');
        expect(deleted, 1);
        expect(await reopened.aiCacheDao.read('translation', 'paired'), isNull);
        expect(
          await reopened.aiCacheDao.read('translation', 'pairless'),
          isNotNull,
        );
        expect(
          await reopened.aiCacheDao.read('translation', 'other'),
          isNotNull,
        );
        expect(
          await reopened.aiCacheDao.read('translation', 'malformed'),
          isNotNull,
          reason: 'json_valid guard must keep undecodable payloads intact',
        );

        final pairIndex = await reopened
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name = 'idx_ai_cache_lang_pair'",
            )
            .get();
        expect(pairIndex, hasLength(1));
      },
    );
  });
}
