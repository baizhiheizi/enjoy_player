import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';

void main() {
  late AppDatabase db;
  late TranscriptRepository repo;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = TranscriptRepository(db);
    final now = DateTime.utc(2026);
    await db.audioDao.insertRow(
      AudioRow(
        id: 'audio-1',
        aid: 'aid-1',
        provider: 'user',
        title: 'Audio',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 10,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///audio-1.wav',
        md5: null,
        size: 1,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() => db.close());

  test(
    'upserts one generated row and makes it the primary transcript',
    () async {
      const firstLines = <TranscriptLine>[
        TranscriptLine(text: 'First line.', startMs: 0, durationMs: 1000),
      ];
      final firstId = await repo.upsertAsrGeneratedTrack(
        mediaId: 'audio-1',
        language: 'en',
        lines: firstLines,
      );
      final first = await db.transcriptDao.getById(firstId!);

      await Future<void>.delayed(const Duration(milliseconds: 1));
      const replacementLines = <TranscriptLine>[
        TranscriptLine(text: 'Replacement line.', startMs: 0, durationMs: 1200),
      ];
      final secondId = await repo.upsertAsrGeneratedTrack(
        mediaId: 'audio-1',
        language: 'en',
        lines: replacementLines,
      );
      final rows = await db.transcriptDao.listForTarget('Audio', 'audio-1');
      final updated = await db.transcriptDao.getById(secondId!);
      final session = await db.echoSessionDao.getLatestForTarget(
        'Audio',
        'audio-1',
      );

      expect(secondId, firstId);
      expect(rows, hasLength(1));
      expect(updated?.createdAt, first?.createdAt);
      expect(updated?.label, 'Generated (en)');
      expect(session?.transcriptId, firstId);
      expect(
        jsonDecode(updated!.timelineJson),
        equals(replacementLines.map((line) => line.toJson()).toList()),
      );
      final roundTripped = (jsonDecode(updated.timelineJson) as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(TranscriptLine.fromJson)
          .toList();
      expect(roundTripped, replacementLines);
    },
  );
}
