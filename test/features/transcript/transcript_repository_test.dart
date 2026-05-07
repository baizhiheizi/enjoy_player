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
      String linesJson = '[{"text":"a","start":0,"duration":1000}]',
    }) {
      final now = DateTime.now();
      return TranscriptRow(
        id: id,
        mediaId: 'm1',
        language: 'und',
        source: 'import',
        linesJson: linesJson,
        label: 'L',
        trackIndex: null,
        isEmbedded: false,
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
        linesJson: '[{"text":"b","start":0,"duration":500}]',
      );
      final c = repo.linesForRow(r2);
      expect(identical(a, c), isFalse);
      expect(c.first.text, 'b');
    });

    test('setActiveTranscript and setSecondaryTranscript update session', () async {
      final now = DateTime.now();
      await db.mediaDao.insertRow(
        MediaRow(
          id: 'm1',
          kind: 'audio',
          title: 't',
          sourceUri: 'file:///a.mp3',
          thumbnailPath: null,
          durationMs: 0,
          language: 'und',
          fileHash: 'f',
          fileSize: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.sessionDao.upsert(
        PlaybackSessionRow(
          mediaId: 'm1',
          positionMs: 0,
          currentSegmentIndex: -1,
          echoActive: false,
          echoStartLine: -1,
          echoEndLine: -1,
          echoStartMs: 0,
          echoEndMs: 0,
          primaryTranscriptId: null,
          secondaryTranscriptId: null,
          lastActiveAt: now,
        ),
      );

      final tid = 'tr-1';
      final linesJson = jsonEncode(
        [
          const TranscriptLine(text: 'x', startMs: 0, durationMs: 100).toJson(),
        ],
      );

      await db.transcriptDao.upsert(
        TranscriptRow(
          id: tid,
          mediaId: 'm1',
          language: 'en',
          source: 'import',
          linesJson: linesJson,
          label: 'en',
          trackIndex: null,
          isEmbedded: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repo.setActiveTranscript('m1', tid);
      await repo.setSecondaryTranscript('m1', tid);

      final s = await db.sessionDao.getForMedia('m1');
      expect(s?.primaryTranscriptId, tid);
      expect(s?.secondaryTranscriptId, tid);
    });
  });
}
