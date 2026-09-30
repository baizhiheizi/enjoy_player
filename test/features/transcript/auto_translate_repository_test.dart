import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> insertPrimaryInto(
  AppDatabase db, {
  required String mediaId,
  required List<TranscriptLine> lines,
}) async {
  final now = DateTime.now();
  await db.videoDao.insertRow(
    VideoRow(
      id: mediaId,
      vid: 'vid12345678',
      provider: 'user',
      title: 'Test',
      description: null,
      thumbnailUrl: null,
      durationSeconds: 60,
      language: 'en',
      source: 'local',
      localUri: '/tmp/test.mp4',
      md5: null,
      size: null,
      mediaUrl: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
  final primaryId = enjoyTranscriptId(
    targetType: 'Video',
    targetId: mediaId,
    language: 'en',
    source: 'user',
  );
  await db.transcriptDao.upsert(
    TranscriptRow(
      id: primaryId,
      targetType: 'Video',
      targetId: mediaId,
      language: 'en',
      source: 'user',
      timelineJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
      referenceId: null,
      label: 'English',
      trackIndex: null,
      syncStatus: 'local',
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.echoSessionDao.updatePrimaryTranscriptForTarget(
    'Video',
    mediaId,
    primaryId,
  );
  return primaryId;
}

void main() {
  group('TranscriptRepository auto-translate helpers', () {
    late AppDatabase db;
    late TranscriptRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = TranscriptRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<String> insertPrimary({
      required String mediaId,
      required List<TranscriptLine> lines,
    }) => insertPrimaryInto(db, mediaId: mediaId, lines: lines);

    test('ensureAutoTranslateTrack upserts skeleton ai row', () async {
      const mediaId = 'media-auto-1';
      const lines = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
      ];
      final primaryId = await insertPrimary(mediaId: mediaId, lines: lines);

      final aiId = await repo.ensureAutoTranslateTrack(
        mediaId: mediaId,
        primaryTranscriptId: primaryId,
        targetLanguage: 'zh-CN',
        primaryLines: lines,
      );

      expect(aiId, isNotNull);
      expect(
        aiId,
        autoTranslateAiTrackId(
          targetType: 'Video',
          mediaId: mediaId,
          targetLanguage: 'zh-CN',
        ),
      );

      final row = await db.transcriptDao.getById(aiId!);
      expect(row?.source, 'ai');
      expect(row?.referenceId, primaryId);
      final decoded = repo.linesForRow(row!);
      expect(decoded.length, 1);
      expect(decoded.first.text, '');
      expect(decoded.first.startMs, 0);
    });

    test(
      'updateAutoTranslateLineText persists one line with sourceKey',
      () async {
        const mediaId = 'media-auto-2';
        const lines = [
          TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
        ];
        final primaryId = await insertPrimary(mediaId: mediaId, lines: lines);
        final aiId = (await repo.ensureAutoTranslateTrack(
          mediaId: mediaId,
          primaryTranscriptId: primaryId,
          targetLanguage: 'zh-CN',
          primaryLines: lines,
        ))!;

        final key = autoTranslateSourceKey(
          primaryText: 'Hello',
          sourceLanguage: 'en',
          targetLanguage: 'zh-CN',
        );
        await repo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 0,
          text: '你好',
          sourceKey: key,
        );
        await repo.flushAutoTranslateWrites();

        final row = await db.transcriptDao.getById(aiId);
        final cue = repo.linesForRow(row!).first;
        expect(cue.text, '你好');
        expect(cue.sourceKey, key);
        final decoded = jsonDecode(row.timelineJson) as List<dynamic>;
        expect((decoded.first as Map)['sourceKey'], key);
      },
    );

    test('setSecondaryTranscript wires echo session', () async {
      const mediaId = 'media-auto-3';
      const lines = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
      ];
      final primaryId = await insertPrimary(mediaId: mediaId, lines: lines);
      final aiId = (await repo.ensureAutoTranslateTrack(
        mediaId: mediaId,
        primaryTranscriptId: primaryId,
        targetLanguage: 'zh-CN',
        primaryLines: lines,
      ))!;

      await repo.setSecondaryTranscript(mediaId, aiId);
      final session = await db.echoSessionDao.getLatestForTarget(
        'Video',
        mediaId,
      );
      expect(session?.secondaryTranscriptId, aiId);
    });

    test('ensureAutoTranslateTrack preserves cached translations', () async {
      const mediaId = 'media-auto-cache';
      const lines = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'World', startMs: 1000, durationMs: 500),
      ];
      final primaryId = await insertPrimary(mediaId: mediaId, lines: lines);
      final aiId = (await repo.ensureAutoTranslateTrack(
        mediaId: mediaId,
        primaryTranscriptId: primaryId,
        targetLanguage: 'zh-CN',
        primaryLines: lines,
      ))!;

      await repo.updateAutoTranslateLineText(
        aiTranscriptId: aiId,
        lineIndex: 0,
        text: '你好',
      );
      await repo.updateAutoTranslateLineText(
        aiTranscriptId: aiId,
        lineIndex: 1,
        text: '世界',
      );
      await repo.flushAutoTranslateWrites();

      final again = await repo.ensureAutoTranslateTrack(
        mediaId: mediaId,
        primaryTranscriptId: primaryId,
        targetLanguage: 'zh-CN',
        primaryLines: lines,
      );
      expect(again, aiId);

      final row = await db.transcriptDao.getById(aiId);
      final decoded = repo.linesForRow(row!);
      expect(decoded[0].text, '你好');
      expect(decoded[1].text, '世界');
      final raw = jsonDecode(row.timelineJson) as List<dynamic>;
      expect((raw[0] as Map)['text'], '你好');
      expect((raw[1] as Map)['text'], '世界');
    });
  });

  group('TranscriptRepository auto-translate flush cadence (#810 D1)', () {
    late _SpyDatabase spyDb;
    late TranscriptRepository spyRepo;

    setUp(() {
      spyDb = _SpyDatabase();
      spyRepo = TranscriptRepository(spyDb);
    });

    tearDown(() async {
      await spyDb.close();
    });

    Future<String> seedAiTrack({
      required String mediaId,
      required List<TranscriptLine> lines,
    }) async {
      final primaryId = await insertPrimaryInto(
        spyDb,
        mediaId: mediaId,
        lines: lines,
      );
      return (await spyRepo.ensureAutoTranslateTrack(
        mediaId: mediaId,
        primaryTranscriptId: primaryId,
        targetLanguage: 'zh-CN',
        primaryLines: lines,
      ))!;
    }

    test('N buffered lines flush as a single row write', () async {
      const mediaId = 'media-flush-1';
      final lines = List.generate(
        8,
        (i) => TranscriptLine(text: 'L$i', startMs: i * 1000, durationMs: 900),
      );
      final aiId = await seedAiTrack(mediaId: mediaId, lines: lines);
      spyDb.transcriptUpsertIds.clear();

      for (var i = 0; i < lines.length; i++) {
        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: i,
          text: '译$i',
        );
      }
      expect(spyDb.transcriptUpsertIds, isEmpty);

      await spyRepo.flushAutoTranslateWrites();

      expect(spyDb.transcriptUpsertIds, [aiId]);
      final row = await spyDb.transcriptDao.getById(aiId);
      final decoded = spyRepo.linesForRow(row!);
      expect(decoded[3].text, '译3');
      expect(decoded[7].text, '译7');
    });

    test(
      'buffered lines are visible through linesForRow before the flush',
      () async {
        const mediaId = 'media-flush-2';
        const lines = [
          TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
          TranscriptLine(text: 'World', startMs: 1000, durationMs: 500),
        ];
        final aiId = await seedAiTrack(mediaId: mediaId, lines: lines);

        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 1,
          text: '世界',
        );

        final row = await spyDb.transcriptDao.getById(aiId);
        final overlay = spyRepo.linesForRow(row!);
        expect(overlay[1].text, '世界');
        expect(overlay[0].text, '');

        await spyRepo.flushAutoTranslateWrites();
        final flushed = spyRepo.linesForRow(
          (await spyDb.transcriptDao.getById(aiId))!,
        );
        expect(flushed[1].text, '世界');
      },
    );

    test('the debounce timer flushes without an explicit call', () async {
      const mediaId = 'media-flush-3';
      const lines = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 900),
      ];
      final aiId = await seedAiTrack(mediaId: mediaId, lines: lines);

      await spyRepo.updateAutoTranslateLineText(
        aiTranscriptId: aiId,
        lineIndex: 0,
        text: '你好',
      );
      await Future<void>.delayed(
        kAutoTranslateFlushInterval + const Duration(milliseconds: 200),
      );

      final row = await spyDb.transcriptDao.getById(aiId);
      final raw = jsonDecode(row!.timelineJson) as List<dynamic>;
      expect((raw.first as Map)['text'], '你好');
    });

    test(
      'a pending flush merges with a re-opened session in one write',
      () async {
        const mediaId = 'media-flush-4';
        final lines = List.generate(
          4,
          (i) =>
              TranscriptLine(text: 'L$i', startMs: i * 1000, durationMs: 900),
        );
        final aiId = await seedAiTrack(mediaId: mediaId, lines: lines);
        spyDb.transcriptUpsertIds.clear();

        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 0,
          text: '译0',
        );
        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 1,
          text: '译1',
        );

        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 2,
          text: '译2',
        );
        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 3,
          text: '译3',
        );
        await spyRepo.flushAutoTranslateWrites();

        expect(spyDb.transcriptUpsertIds, [aiId]);
        final row = await spyDb.transcriptDao.getById(aiId);
        final decoded = spyRepo.linesForRow(row!);
        expect(decoded.map((l) => l.text), ['译0', '译1', '译2', '译3']);
      },
    );

    test('a stale rebuild drops pending line updates', () async {
      const mediaId = 'media-flush-5';
      const lines = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'World', startMs: 1000, durationMs: 500),
      ];
      final primaryId = await insertPrimaryInto(
        spyDb,
        mediaId: mediaId,
        lines: lines,
      );
      final aiId = await seedAiTrack(mediaId: mediaId, lines: lines);

      await spyRepo.updateAutoTranslateLineText(
        aiTranscriptId: aiId,
        lineIndex: 0,
        text: '你好',
      );

      final aiRow = (await spyDb.transcriptDao.getById(aiId))!;
      await spyDb.transcriptDao.upsert(
        aiRow.copyWith(referenceId: const Value('another-primary')),
      );

      final rebuilt = await spyRepo.ensureAutoTranslateTrack(
        mediaId: mediaId,
        primaryTranscriptId: primaryId,
        targetLanguage: 'zh-CN',
        primaryLines: lines,
      );
      expect(rebuilt, aiId);
      await spyRepo.flushAutoTranslateWrites();

      final row = await spyDb.transcriptDao.getById(aiId);
      final decoded = spyRepo.linesForRow(row!);
      expect(decoded[0].text, '');
    });

    test(
      'deleteTranscript drops pending updates for the deleted row',
      () async {
        const mediaId = 'media-flush-6';
        const lines = [
          TranscriptLine(text: 'Hello', startMs: 0, durationMs: 900),
        ];
        final aiId = await seedAiTrack(mediaId: mediaId, lines: lines);
        spyDb.transcriptUpsertIds.clear();

        await spyRepo.updateAutoTranslateLineText(
          aiTranscriptId: aiId,
          lineIndex: 0,
          text: '你好',
        );
        await spyRepo.deleteTranscript(aiId);
        await spyRepo.flushAutoTranslateWrites();

        expect(await spyDb.transcriptDao.getById(aiId), isNull);
        expect(spyDb.transcriptUpsertIds, isEmpty);
      },
    );
  });
}

class _CountingTranscriptDao extends TranscriptDao {
  _CountingTranscriptDao(super.db);

  final List<String> upsertedIds = <String>[];

  @override
  Future<void> upsert(TranscriptRow row) {
    upsertedIds.add(row.id);
    return super.upsert(row);
  }
}

class _SpyDatabase extends AppDatabase {
  _SpyDatabase() : super(executor: NativeDatabase.memory());

  late final _CountingTranscriptDao _spyDao = _CountingTranscriptDao(this);

  List<String> get transcriptUpsertIds => _spyDao.upsertedIds;

  @override
  TranscriptDao get transcriptDao => _spyDao;
}
