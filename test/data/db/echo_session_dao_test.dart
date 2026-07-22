import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('EchoSessionDao', () {
    test(
      'getOrCreateLatestForTarget creates a new session when none exists',
      () async {
        final session = await db.echoSessionDao.getOrCreateLatestForTarget(
          'Audio',
          'audio-1',
        );

        expect(session.targetType, 'Audio');
        expect(session.targetId, 'audio-1');
        expect(session.echoActive, isFalse);
        expect(session.currentSegmentIndex, -1);
        expect(session.recordingsCount, 0);
      },
    );

    test('getOrCreateLatestForTarget returns existing session', () async {
      final first = await db.echoSessionDao.getOrCreateLatestForTarget(
        'Audio',
        'audio-1',
      );
      final second = await db.echoSessionDao.getOrCreateLatestForTarget(
        'Audio',
        'audio-1',
      );

      expect(second.id, first.id);
    });

    test('getLatestForTarget returns null when no session exists', () async {
      final result = await db.echoSessionDao.getLatestForTarget(
        'Video',
        'nonexistent',
      );
      expect(result, isNull);
    });

    test('getLatestForTarget returns most recent by lastActiveAt', () async {
      final older = await db.echoSessionDao.getOrCreateLatestForTarget(
        'Audio',
        'audio-1',
      );
      await db.echoSessionDao.upsert(
        older.copyWith(lastActiveAt: DateTime(2025, 1, 1)),
      );

      final newer = EchoSessionRow(
        id: 'newer-id',
        targetType: 'Audio',
        targetId: 'audio-1',
        language: 'und',
        currentTimeMs: 0,
        playbackRate: 1,
        volume: 1,
        echoStartMs: null,
        echoEndMs: null,
        transcriptId: null,
        secondaryTranscriptId: null,
        recordingsCount: 0,
        recordingsDurationMs: 0,
        lastRecordingAt: null,
        currentSegmentIndex: -1,
        echoActive: false,
        echoStartLine: -1,
        echoEndLine: -1,
        blurActive: false,
        startedAt: DateTime(2025, 6, 1),
        lastActiveAt: DateTime(2025, 6, 1),
        completedAt: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1),
      );
      await db.echoSessionDao.upsert(newer);

      final latest = await db.echoSessionDao.getLatestForTarget(
        'Audio',
        'audio-1',
      );
      expect(latest!.id, 'newer-id');
    });

    test('upsert replaces existing row', () async {
      final session = await db.echoSessionDao.getOrCreateLatestForTarget(
        'Audio',
        'audio-1',
      );

      await db.echoSessionDao.upsert(
        session.copyWith(echoActive: true, currentSegmentIndex: 3),
      );

      final updated = await db.echoSessionDao.getLatestForTarget(
        'Audio',
        'audio-1',
      );
      expect(updated!.echoActive, isTrue);
      expect(updated.currentSegmentIndex, 3);
    });

    test(
      'updatePrimaryTranscriptForTarget creates session if none exists',
      () async {
        await db.echoSessionDao.updatePrimaryTranscriptForTarget(
          'Video',
          'video-1',
          'transcript-abc',
        );

        final session = await db.echoSessionDao.getLatestForTarget(
          'Video',
          'video-1',
        );
        expect(session, isNotNull);
        expect(session!.transcriptId, 'transcript-abc');
      },
    );

    test('updatePrimaryTranscriptForTarget updates existing session', () async {
      await db.echoSessionDao.getOrCreateLatestForTarget('Video', 'video-1');

      await db.echoSessionDao.updatePrimaryTranscriptForTarget(
        'Video',
        'video-1',
        'transcript-xyz',
      );

      final session = await db.echoSessionDao.getLatestForTarget(
        'Video',
        'video-1',
      );
      expect(session!.transcriptId, 'transcript-xyz');
    });

    test(
      'updateSecondaryTranscriptForTarget creates session if none exists',
      () async {
        await db.echoSessionDao.updateSecondaryTranscriptForTarget(
          'Audio',
          'audio-2',
          'secondary-transcript',
        );

        final session = await db.echoSessionDao.getLatestForTarget(
          'Audio',
          'audio-2',
        );
        expect(session, isNotNull);
        expect(session!.secondaryTranscriptId, 'secondary-transcript');
      },
    );

    test(
      'updateSecondaryTranscriptForTarget updates existing session',
      () async {
        await db.echoSessionDao.getOrCreateLatestForTarget('Audio', 'audio-2');

        await db.echoSessionDao.updateSecondaryTranscriptForTarget(
          'Audio',
          'audio-2',
          'new-secondary',
        );

        final session = await db.echoSessionDao.getLatestForTarget(
          'Audio',
          'audio-2',
        );
        expect(session!.secondaryTranscriptId, 'new-secondary');
      },
    );

    test('practiceTotals returns zero when no sessions', () async {
      final totals = await db.echoSessionDao.practiceTotals();
      expect(totals.sessionCount, 0);
      expect(totals.recordingsDurationMs, 0);
    });

    test('practiceTotals aggregates across sessions', () async {
      final s1 = await db.echoSessionDao.getOrCreateLatestForTarget(
        'Audio',
        'a1',
      );
      await db.echoSessionDao.upsert(s1.copyWith(recordingsDurationMs: 5000));

      final s2 = await db.echoSessionDao.getOrCreateLatestForTarget(
        'Video',
        'v1',
      );
      await db.echoSessionDao.upsert(s2.copyWith(recordingsDurationMs: 3000));

      final totals = await db.echoSessionDao.practiceTotals();
      expect(totals.sessionCount, 2);
      expect(totals.recordingsDurationMs, 8000);
    });
  });

  group('recordingOverlapsEchoRegion', () {
    RecordingRow makeRecording(int start, int duration) {
      final now = DateTime(2025, 1, 1);
      return RecordingRow(
        id: 'r',
        targetType: 'Audio',
        targetId: 'a1',
        referenceStart: start,
        referenceDuration: duration,
        referenceText: 'test',
        language: 'en',
        duration: 1000,
        md5: null,
        audioUrl: null,
        pronunciationScore: null,
        assessmentJson: null,
        localPath: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('returns true when recording fully inside echo region', () {
      final r = makeRecording(1000, 500);
      expect(recordingOverlapsEchoRegion(r, 0, 3000), isTrue);
    });

    test('returns true when recording partially overlaps start', () {
      final r = makeRecording(0, 1500);
      expect(recordingOverlapsEchoRegion(r, 1000, 3000), isTrue);
    });

    test('returns true when recording partially overlaps end', () {
      final r = makeRecording(2500, 1000);
      expect(recordingOverlapsEchoRegion(r, 0, 3000), isTrue);
    });

    test('returns true when recording fully contains echo region', () {
      final r = makeRecording(0, 5000);
      expect(recordingOverlapsEchoRegion(r, 1000, 3000), isTrue);
    });

    test('returns false when recording is entirely before echo region', () {
      final r = makeRecording(0, 500);
      expect(recordingOverlapsEchoRegion(r, 1000, 3000), isFalse);
    });

    test('returns false when recording is entirely after echo region', () {
      final r = makeRecording(4000, 1000);
      expect(recordingOverlapsEchoRegion(r, 0, 3000), isFalse);
    });

    test('returns false when recording ends exactly at echo start', () {
      final r = makeRecording(0, 1000);
      expect(recordingOverlapsEchoRegion(r, 1000, 3000), isFalse);
    });

    test('returns false when recording starts exactly at echo end', () {
      final r = makeRecording(3000, 1000);
      expect(recordingOverlapsEchoRegion(r, 0, 3000), isFalse);
    });
  });
}
