import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dexieTargetTypeForId resolves Audio row', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.audioDao.insertRow(
      AudioRow(
        id: 'media-1',
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
    expect(await dexieTargetTypeForId(db, 'media-1'), 'Audio');
  });

  test('primary transcript lines decode via TranscriptRepository', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    const mediaId = 'media-1';
    const transcriptId = 'tr-1';

    await db.audioDao.insertRow(
      AudioRow(
        id: mediaId,
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

    final timelineJson = jsonEncode(
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
        targetType: 'Audio',
        targetId: mediaId,
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

    await db.echoSessionDao.upsert(
      EchoSessionRow(
        id: 'echo-1',
        targetType: 'Audio',
        targetId: mediaId,
        language: 'und',
        currentTimeMs: 0,
        playbackRate: 1,
        volume: 1,
        echoStartMs: null,
        echoEndMs: null,
        transcriptId: transcriptId,
        secondaryTranscriptId: null,
        recordingsCount: 0,
        recordingsDurationMs: 0,
        lastRecordingAt: null,
        currentSegmentIndex: -1,
        echoActive: false,
        echoStartLine: -1,
        echoEndLine: -1,
        startedAt: now,
        lastActiveAt: now,
        completedAt: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final repo = TranscriptRepository(db);
    final row = await repo.primaryTranscriptRowForMedia(mediaId);
    expect(row, isNotNull);
    final lines = repo.linesForRow(row!);
    expect(lines, hasLength(1));
    expect(lines.single.text, 'hello');
  });
}
