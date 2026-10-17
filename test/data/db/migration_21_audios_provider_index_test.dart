/// Migration 21 test (issue #968 C2): `audios(provider)` index backing the
/// provider-scoped library views used by Craft history.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migration 21 — audios provider index (issue #968 C2)', () {
    test('schemaVersion is at least 21', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(21));
    });

    test('fresh installs create the index', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_audios_provider'",
          )
          .get();
      expect(indexes, hasLength(1));
    });

    test('upgrade from v20 creates the index and serves the provider '
        'lookup from it', () async {
      final file = File(
        '${Directory.systemTemp.path}/'
        'migration_21_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final seed = AppDatabase(executor: NativeDatabase(file));
      await seed.customStatement('PRAGMA user_version = 20');
      await seed.audioDao.insertRow(
        AudioRow(
          id: 'a-1',
          aid: 'aid-1',
          provider: 'craft',
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
            "AND name = 'idx_audios_provider'",
          )
          .get();
      expect(indexes, hasLength(1));

      final plan = await reopened
          .customSelect(
            'EXPLAIN QUERY PLAN '
            "SELECT id FROM audios WHERE provider = 'craft'",
          )
          .get();
      final planText = plan.map((r) => r.read<String>('detail')).join('\n');
      expect(planText, contains('idx_audios_provider'));
    });
  });
}
