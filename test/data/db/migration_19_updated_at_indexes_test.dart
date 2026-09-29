/// Migration 19 test (issue #810 D6): `updated_at DESC` indexes backing the
/// Home recents `LIMIT 12 ORDER BY updated_at DESC` query on the `videos` /
/// `audios` tables.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migration 19 — updated_at indexes (issue #810 D6)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is at least 19', () {
      expect(db.schemaVersion, greaterThanOrEqualTo(19));
    });

    test('upgrade from v18 creates both updated_at indexes and serves the '
        'recents ORDER BY from them', () async {
      final file = File(
        '${Directory.systemTemp.path}/'
        'migration_19_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final seed = AppDatabase(executor: NativeDatabase(file));
      await seed.customStatement('PRAGMA user_version = 18');
      await seed.videoDao.insertRow(
        VideoRow(
          id: 'v-1',
          vid: 'vid-1',
          provider: 'user',
          title: 'Seed',
          durationSeconds: 0,
          language: 'und',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await seed.close();

      final reopened = AppDatabase(executor: NativeDatabase(file));
      addTearDown(reopened.close);
      await reopened.customSelect('SELECT 1').get();

      final indexes = await reopened
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_%_updated_at'",
          )
          .get();
      final names = indexes.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(['idx_videos_updated_at', 'idx_audios_updated_at']),
      );

      final plan = await reopened
          .customSelect(
            'EXPLAIN QUERY PLAN '
            'SELECT id FROM videos ORDER BY updated_at DESC LIMIT 12',
          )
          .get();
      final planText = plan.map((r) => r.read<String>('detail')).join('\n');
      expect(planText, contains('idx_videos_updated_at'));
    });
  });
}
