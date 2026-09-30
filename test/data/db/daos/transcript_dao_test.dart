import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptRow _transcript({
  String id = 't-1',
  String targetType = 'video',
  String targetId = 'v-1',
  String language = 'en',
  String source = 'manual',
  String timelineJson = '{"cues":[]}',
  String? referenceId,
  String label = 'primary',
  int? trackIndex,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return TranscriptRow(
    id: id,
    targetType: targetType,
    targetId: targetId,
    language: language,
    source: source,
    timelineJson: timelineJson,
    referenceId: referenceId,
    label: label,
    trackIndex: trackIndex,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TranscriptDao', () {
    test('upsert persists and getById reads it back', () async {
      await db.transcriptDao.upsert(_transcript(id: 't-1'));
      final found = await db.transcriptDao.getById('t-1');
      expect(found, isNotNull);
      expect(found!.language, 'en');
    });

    test('getById returns null for missing id', () async {
      expect(await db.transcriptDao.getById('missing'), isNull);
    });

    test('upsert replaces by primary key', () async {
      await db.transcriptDao.upsert(_transcript(id: 't-1', label: 'first'));
      await db.transcriptDao.upsert(_transcript(id: 't-1', label: 'second'));
      final found = await db.transcriptDao.getById('t-1');
      expect(found!.label, 'second');
    });

    test('listForTarget returns matching transcripts only', () async {
      await db.transcriptDao.upsert(
        _transcript(id: 't-1', targetType: 'video', targetId: 'v-1'),
      );
      await db.transcriptDao.upsert(
        _transcript(id: 't-2', targetType: 'video', targetId: 'v-1'),
      );
      await db.transcriptDao.upsert(
        _transcript(id: 't-3', targetType: 'video', targetId: 'v-2'),
      );
      final list = await db.transcriptDao.listForTarget('video', 'v-1');
      expect(list.map((r) => r.id), unorderedEquals(['t-1', 't-2']));
    });

    test('listForTarget returns empty for unknown target', () async {
      await db.transcriptDao.upsert(_transcript(id: 't-1'));
      expect(await db.transcriptDao.listForTarget('video', 'unknown'), isEmpty);
    });

    test('deleteId removes the row', () async {
      await db.transcriptDao.upsert(_transcript(id: 'kill'));
      await db.transcriptDao.upsert(_transcript(id: 'keep'));
      await db.transcriptDao.deleteId('kill');
      expect(await db.transcriptDao.getById('kill'), isNull);
      expect(await db.transcriptDao.getById('keep'), isNotNull);
    });

    test(
      'upsert nudges updatedAt forward on a same-second rewrite (issue #810 D5)',
      () async {
        final first = _transcript(id: 't-1', label: 'first');
        await db.transcriptDao.upsert(first);
        await db.transcriptDao.upsert(_transcript(id: 't-1', label: 'second'));

        final stored = await db.transcriptDao.getById('t-1');
        expect(
          stored!.updatedAt.difference(first.updatedAt),
          const Duration(seconds: 1),
        );
      },
    );

    test(
      'upsert keeps the caller updatedAt when writes are a second apart',
      () async {
        final first = _transcript(id: 't-1');
        await db.transcriptDao.upsert(first);
        final later = _transcript(
          id: 't-1',
          timelineJson: '[{"text":"b","start":0,"duration":100}]',
        ).copyWith(updatedAt: first.updatedAt.add(const Duration(seconds: 2)));
        await db.transcriptDao.upsert(later);

        final stored = await db.transcriptDao.getById('t-1');
        expect(stored!.updatedAt, later.updatedAt);
      },
    );

    test('upsertAll applies the same same-second revision guarantee', () async {
      final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      await db.transcriptDao.upsertAll([
        _transcript(id: 't-1').copyWith(updatedAt: t),
        _transcript(id: 't-2').copyWith(updatedAt: t),
      ]);
      await db.transcriptDao.upsertAll([
        _transcript(id: 't-1', label: 'again').copyWith(updatedAt: t),
      ]);

      expect(
        (await db.transcriptDao.getById('t-1'))!.updatedAt,
        t.add(const Duration(seconds: 1)),
      );
      expect((await db.transcriptDao.getById('t-2'))!.updatedAt, t);
    });

    test(
      'watchSummariesForTarget orders by source, language, createdAt',
      () async {
        final earlier = DateTime.fromMillisecondsSinceEpoch(1600000000000);
        final later = DateTime.fromMillisecondsSinceEpoch(1700000000000);
        await db.transcriptDao.upsert(
          _transcript(
            id: 't-1',
            source: 'yt',
            language: 'en',
          ).copyWith(createdAt: later),
        );
        await db.transcriptDao.upsert(
          _transcript(
            id: 't-2',
            source: 'yt',
            language: 'zh',
          ).copyWith(createdAt: earlier),
        );
        await db.transcriptDao.upsert(
          _transcript(
            id: 't-3',
            source: 'manual',
            language: 'en',
          ).copyWith(createdAt: earlier),
        );
        final list = await db.transcriptDao
            .watchSummariesForTarget('video', 'v-1')
            .first;
        expect(list.map((r) => r.id), ['t-3', 't-1', 't-2']);
      },
    );

    test('watchSummariesForTarget filters by target', () async {
      await db.transcriptDao.upsert(_transcript(id: 't-1', targetId: 'v-1'));
      await db.transcriptDao.upsert(_transcript(id: 't-2', targetId: 'v-2'));
      final list = await db.transcriptDao
          .watchSummariesForTarget('video', 'v-1')
          .first;
      expect(list.single.id, 't-1');
    });

    test(
      'watchSummariesForTarget fires on row change and carries light columns',
      () async {
        await db.transcriptDao.upsert(
          _transcript(id: 't-1', label: 'first', trackIndex: 3),
        );
        final emissions = <List<TranscriptTrackSummary>>[];
        final sub = db.transcriptDao
            .watchSummariesForTarget('video', 'v-1')
            .listen(emissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await db.transcriptDao.upsert(
          _transcript(id: 't-1', label: 'second', trackIndex: 3),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await sub.cancel();

        expect(emissions, hasLength(2));
        final first = emissions.first.single;
        expect(first.id, 't-1');
        expect(first.label, 'first');
        expect(first.targetType, 'video');
        expect(first.targetId, 'v-1');
        expect(first.language, 'en');
        expect(first.source, 'manual');
        expect(first.trackIndex, 3);
        expect(emissions.last.single.label, 'second');
      },
    );

    test('watchExistsForTarget emits false when empty', () async {
      final exists = await db.transcriptDao
          .watchExistsForTarget('video', 'unknown')
          .first;
      expect(exists, isFalse);
    });

    test('watchExistsForTarget emits true after insert', () async {
      await db.transcriptDao.upsert(_transcript(id: 't-1'));
      final exists = await db.transcriptDao
          .watchExistsForTarget('video', 'v-1')
          .first;
      expect(exists, isTrue);
    });

    test('watchExistsForTarget emits false again after delete', () async {
      await db.transcriptDao.upsert(_transcript(id: 't-1'));
      await db.transcriptDao.deleteId('t-1');
      final exists = await db.transcriptDao
          .watchExistsForTarget('video', 'v-1')
          .first;
      expect(exists, isFalse);
    });
  });
}
