import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiCacheDao', () {
    late AppDatabase db;
    late AiCacheDao dao;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      dao = db.aiCacheDao;
    });

    tearDown(() async {
      await db.close();
    });

    test('read returns row on hit', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{"x":1}', now);
      final row = await dao.read('translation', 'k1');
      expect(row, isNotNull);
      expect(row!.kind, 'translation');
      expect(row.key, 'k1');
      expect(row.payloadJson, '{"x":1}');
      expect(row.updatedAt, now.millisecondsSinceEpoch);
    });

    test('read returns null on miss', () async {
      final row = await dao.read('translation', 'missing');
      expect(row, isNull);
    });

    test('upsert inserts and replaces', () async {
      final t1 = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{"v":1}', t1);
      await dao.upsert(
        'translation',
        'k1',
        '{"v":2}',
        t1.add(const Duration(seconds: 1)),
      );
      final row = await dao.read('translation', 'k1');
      expect(row, isNotNull);
      expect(row!.payloadJson, '{"v":2}');
      expect(
        row.updatedAt,
        t1.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
      );
    });

    test('upsert is isolated by (kind, key)', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{"v":1}', now);
      await dao.upsert('dictionary', 'k1', '{"v":2}', now);
      expect((await dao.read('translation', 'k1'))!.payloadJson, '{"v":1}');
      expect((await dao.read('dictionary', 'k1'))!.payloadJson, '{"v":2}');
    });

    test('delete removes a single row', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{"v":1}', now);
      await dao.upsert('translation', 'k2', '{"v":2}', now);
      await dao.deleteRow('translation', 'k1');
      expect(await dao.read('translation', 'k1'), isNull);
      expect(await dao.read('translation', 'k2'), isNotNull);
    });

    test('delete is a no-op for absent key', () async {
      await dao.deleteRow('translation', 'nope');
      // Should not throw.
      expect(await dao.read('translation', 'nope'), isNull);
    });

    test('deleteForKind drops every row for the kind', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{"v":1}', now);
      await dao.upsert('translation', 'k2', '{"v":2}', now);
      await dao.upsert('dictionary', 'k1', '{"v":3}', now);
      await dao.deleteForKind('translation');
      expect(await dao.countForKind('translation'), 0);
      expect(await dao.countForKind('dictionary'), 1);
    });

    test('evictOldestExcept keeps the most-recent rows', () async {
      final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      // Insert 5 rows with ascending updatedAt.
      for (var i = 0; i < 5; i++) {
        await dao.upsert(
          'translation',
          'k$i',
          '{"v":$i}',
          base.add(Duration(seconds: i)),
        );
      }
      final deleted = await dao.evictOldestExcept('translation', 2);
      expect(deleted, 3);
      expect(await dao.countForKind('translation'), 2);
      // The two kept rows must be the most recent: k3 and k4.
      expect((await dao.read('translation', 'k3'))!.payloadJson, '{"v":3}');
      expect((await dao.read('translation', 'k4'))!.payloadJson, '{"v":4}');
      expect(await dao.read('translation', 'k0'), isNull);
      expect(await dao.read('translation', 'k1'), isNull);
      expect(await dao.read('translation', 'k2'), isNull);
    });

    test('evictOldestExcept is a no-op when count <= keep', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{}', now);
      await dao.upsert('translation', 'k2', '{}', now);
      final deleted = await dao.evictOldestExcept('translation', 5);
      expect(deleted, 0);
      expect(await dao.countForKind('translation'), 2);
    });

    test('pruneOlderThan removes rows older than the cutoff', () async {
      final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'old1', '{}', base);
      await dao.upsert(
        'translation',
        'old2',
        '{}',
        base.add(const Duration(seconds: 1)),
      );
      await dao.upsert(
        'translation',
        'new1',
        '{}',
        base.add(const Duration(seconds: 100)),
      );
      final cutoff = base.add(const Duration(seconds: 10));
      final deleted = await dao.pruneOlderThan('translation', cutoff);
      expect(deleted, 2);
      expect(await dao.countForKind('translation'), 1);
      expect((await dao.read('translation', 'new1')), isNotNull);
    });

    test('countForKind returns the row count', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await dao.upsert('translation', 'k1', '{}', now);
      await dao.upsert('translation', 'k2', '{}', now);
      await dao.upsert('dictionary', 'k1', '{}', now);
      expect(await dao.countForKind('translation'), 2);
      expect(await dao.countForKind('dictionary'), 1);
      expect(await dao.countForKind('contextual_translation'), 0);
    });
  });
}
