import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptRepository', () {
    late AppDatabase db;
    late TranscriptRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TranscriptRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    TranscriptRow makeRow({
      required String id,
      required DateTime updatedAt,
      String timelineJson = '[{"text":"a","start":0,"duration":1000}]',
    }) {
      final now = DateTime.now();
      return TranscriptRow(
        id: id,
        targetType: 'Audio',
        targetId: 'm1',
        language: 'und',
        source: 'user',
        timelineJson: timelineJson,
        referenceId: null,
        label: 'L',
        trackIndex: null,
        isEmbedded: false,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: updatedAt,
      );
    }

    test('linesForRow memoizes until updatedAt changes', () {
      final t = DateTime.utc(2025, 1, 1);
      final r1 = makeRow(id: 't1', updatedAt: t);
      final a = repo.linesForRow(r1);
      final b = repo.linesForRow(r1);
      expect(identical(a, b), isTrue);

      final r2 = makeRow(
        id: 't1',
        updatedAt: t.add(const Duration(seconds: 1)),
        timelineJson: '[{"text":"b","start":0,"duration":500}]',
      );
      final c = repo.linesForRow(r2);
      expect(identical(a, c), isFalse);
      expect(c.first.text, 'b');
    });

    test('setActiveTranscript and setSecondaryTranscript update session', () async {
      final now = DateTime.now();
      await db.audioDao.insertRow(
        AudioRow(
          id: 'm1',
          aid: 'f',
          provider: 'user',
          title: 't',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: 'file:///a.mp3',
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final tid = 'tr-1';
      final timelineJson = jsonEncode(
        [
          const TranscriptLine(text: 'x', startMs: 0, durationMs: 100).toJson(),
        ],
      );

      await db.transcriptDao.upsert(
        TranscriptRow(
          id: tid,
          targetType: 'Audio',
          targetId: 'm1',
          language: 'en',
          source: 'user',
          timelineJson: timelineJson,
          referenceId: null,
          label: 'en',
          trackIndex: null,
          isEmbedded: false,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repo.setActiveTranscript('m1', tid);
      await repo.setSecondaryTranscript('m1', tid);

      final s = await db.echoSessionDao.getLatestForTarget('Audio', 'm1');
      expect(s?.transcriptId, tid);
      expect(s?.secondaryTranscriptId, tid);
    });
  });
}
