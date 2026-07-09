import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('updateAutoTranslateLineText persists one line', () async {
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

      await repo.updateAutoTranslateLineText(
        aiTranscriptId: aiId,
        lineIndex: 0,
        text: '你好',
      );

      final row = await db.transcriptDao.getById(aiId);
      expect(repo.linesForRow(row!).first.text, '你好');
    });

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

      // Re-select / re-ensure must not wipe finished lines.
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
    });
  });
}
