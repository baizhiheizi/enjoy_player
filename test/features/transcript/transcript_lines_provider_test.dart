import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transcriptLinesForMediaProvider decodes primary transcript', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    const mediaId = 'media-1';
    const transcriptId = 'tr-1';

    await db.mediaDao.insertRow(
      MediaRow(
        id: mediaId,
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

    final linesJson = jsonEncode(
      [
        const TranscriptLine(
          text: 'hello',
          startMs: 0,
          durationMs: 500,
        ).toJson(),
      ],
    );

    await db.transcriptDao.upsert(
      TranscriptRow(
        id: transcriptId,
        mediaId: mediaId,
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

    await db.sessionDao.upsert(
      PlaybackSessionRow(
        mediaId: mediaId,
        positionMs: 0,
        currentSegmentIndex: -1,
        echoActive: false,
        echoStartLine: -1,
        echoEndLine: -1,
        echoStartMs: 0,
        echoEndMs: 0,
        primaryTranscriptId: transcriptId,
        secondaryTranscriptId: null,
        lastActiveAt: now,
      ),
    );

    final repo = TranscriptRepository(db);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transcriptRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final lines = await container.read(
      transcriptLinesForMediaProvider(mediaId).future,
    );

    expect(lines, hasLength(1));
    expect(lines.single.text, 'hello');
  });
}
