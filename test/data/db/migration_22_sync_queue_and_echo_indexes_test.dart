/// Migration 22 test: `sync_queue(entity_type, entity_id, action)` and
/// `echo_sessions(last_active_at DESC)` indexes.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migration 22 — sync_queue and echo_sessions indexes', () {
    test('schemaVersion is at least 22', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(22));
    });

    test('fresh installs create both indexes', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name IN ('idx_sync_queue_entity_action', 'idx_echo_sessions_last_active') "
            'ORDER BY name',
          )
          .get();
      expect(indexes.map((r) => r.read<String>('name')).toList(), [
        'idx_echo_sessions_last_active',
        'idx_sync_queue_entity_action',
      ]);
    });

    test(
      'upgrade from v21 creates both indexes and query plans use them',
      () async {
        final file = File(
          '${Directory.systemTemp.path}/'
          'migration_22_${DateTime.now().microsecondsSinceEpoch}.sqlite',
        );
        addTearDown(() {
          if (file.existsSync()) file.deleteSync();
        });

        final seed = AppDatabase(executor: NativeDatabase(file));
        await seed.customStatement('DROP INDEX idx_sync_queue_entity_action');
        await seed.customStatement('DROP INDEX idx_echo_sessions_last_active');
        await seed.customStatement('PRAGMA user_version = 21');
        await seed.close();

        final reopened = AppDatabase(executor: NativeDatabase(file));
        addTearDown(reopened.close);
        await reopened.customSelect('SELECT 1').get();

        final indexes = await reopened
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name IN ('idx_sync_queue_entity_action', 'idx_echo_sessions_last_active') "
              'ORDER BY name',
            )
            .get();
        expect(indexes.map((r) => r.read<String>('name')).toList(), [
          'idx_echo_sessions_last_active',
          'idx_sync_queue_entity_action',
        ]);

        final queuePlan = await reopened
            .customSelect(
              'EXPLAIN QUERY PLAN '
              "SELECT id FROM sync_queue WHERE entity_type = 'Video' "
              "AND entity_id = 'v1' AND action = 'create'",
            )
            .get();
        expect(
          queuePlan.map((r) => r.read<String>('detail')).join('\n'),
          contains('idx_sync_queue_entity_action'),
        );

        final echoPlan = await reopened
            .customSelect(
              'EXPLAIN QUERY PLAN '
              'SELECT * FROM echo_sessions ORDER BY last_active_at DESC LIMIT 20',
            )
            .get();
        expect(
          echoPlan.map((r) => r.read<String>('detail')).join('\n'),
          contains('idx_echo_sessions_last_active'),
        );
      },
    );
  });
}
