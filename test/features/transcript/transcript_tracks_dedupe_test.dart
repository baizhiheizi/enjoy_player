/// Pins the dedupe behavior of `TranscriptRepository.watchTracks`:
/// identical list emissions must not propagate to subscribers, while real
/// semantic changes (new track, label change) must still propagate.
library;

import 'dart:async';

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/core/utils/stream_distinct.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'media-tracks-dedupe';

String _timeline(List<TranscriptLine> lines) =>
    jsonEncode(lines.map((e) => e.toJson()).toList());

AudioRow _audio() {
  final now = DateTime.utc(2026, 7, 6);
  return AudioRow(
    id: _mediaId,
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
  );
}

TranscriptRow _transcript({
  required String id,
  required String language,
  required String source,
  String label = '',
  int? trackIndex,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime.utc(2026, 7, 6);
  return TranscriptRow(
    id: id,
    targetType: 'Audio',
    targetId: _mediaId,
    language: language,
    source: source,
    timelineJson: _timeline(const [
      TranscriptLine(text: 'cue', startMs: 0, durationMs: 100),
    ]),
    referenceId: null,
    label: label,
    trackIndex: trackIndex,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

EchoSessionRow _echoSession({String? transcriptId}) {
  final now = DateTime.utc(2026, 7, 6);
  return EchoSessionRow(
    id: 'echo-tracks-dedupe',
    targetType: 'Audio',
    targetId: _mediaId,
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranscriptTrack value equality', () {
    test('two tracks with identical fields are ==', () {
      const a = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'official',
        label: 'English (official)',
      );
      const b = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'official',
        label: 'English (official)',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('changing any field breaks ==', () {
      const base = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'official',
        label: 'English',
      );
      const idDiff = TranscriptTrack(
        id: 'tr-2',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'official',
        label: 'English',
      );
      const langDiff = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'ja',
        source: 'official',
        label: 'English',
      );
      const sourceDiff = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'auto',
        label: 'English',
      );
      const labelDiff = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'official',
        label: 'English (US)',
      );
      const idxDiff = TranscriptTrack(
        id: 'tr-1',
        targetType: 'Audio',
        targetId: 'media-1',
        language: 'en',
        source: 'official',
        label: 'English',
        trackIndex: 2,
      );
      expect(base, isNot(equals(idDiff)));
      expect(base, isNot(equals(langDiff)));
      expect(base, isNot(equals(sourceDiff)));
      expect(base, isNot(equals(labelDiff)));
      expect(base, isNot(equals(idxDiff)));
    });
  });

  group('TranscriptRepository.watchTracks dedupe', () {
    late AppDatabase db;
    late TranscriptRepository repo;
    late StreamSubscription<List<TranscriptTrack>> sub;
    final emissions = <List<TranscriptTrack>>[];

    /// Wires up [sub] on `repo.watchTracks(_mediaId)`, waits for the
    /// initial emission to land (up to 2s), then drains so subsequent
    /// action counts are action-only. Returns the initial track list so
    /// the initial-state test can verify it.
    Future<List<TranscriptTrack>> wireAndDrain() async {
      emissions.clear();
      sub = repo.watchTracks(_mediaId).listen(emissions.add);
      addTearDown(() async {
        await sub.cancel();
      });

      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (emissions.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final initial = emissions.toList();
      emissions.clear();
      return initial.isEmpty ? const [] : initial.last;
    }

    setUp(() async {
      db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      repo = TranscriptRepository(db);
      await db.audioDao.insertRow(_audio());
      await db.transcriptDao.upsert(
        _transcript(
          id: 'tr-en-official',
          language: 'en',
          source: 'official',
          label: 'English (official)',
        ),
      );
      await db.transcriptDao.upsert(
        _transcript(
          id: 'tr-ja-auto',
          language: 'ja',
          source: 'auto',
          label: 'Japanese (auto)',
        ),
      );
      await db.echoSessionDao.upsert(
        _echoSession(transcriptId: 'tr-en-official'),
      );
    });

    test(
      'initial emission contains both tracks sorted by source then createdAt',
      () async {
        final initial = await wireAndDrain();
        expect(initial, hasLength(2));
        // Source ordering by `_sourcePriority`: official=0 < auto=1.
        expect(initial[0].source, 'official');
        expect(initial[1].source, 'auto');
      },
    );

    test('skips identical emissions when an unrelated row updates', () async {
      await wireAndDrain();
      // Bump the echo session's recordingsCount — Drift re-emits the
      // echo session, but the resolved track list is unchanged.
      await (db.update(
        db.echoSessions,
      )..where((s) => s.id.equals('echo-tracks-dedupe'))).write(
        EchoSessionsCompanion(
          recordingsCount: const Value(3),
          updatedAt: Value(DateTime.utc(2026, 7, 6, 12)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        emissions,
        isEmpty,
        reason:
            'Echo session update is a no-op for tracks. '
            'Got $emissions',
      );
    });

    test('re-emits when a new track is added', () async {
      await wireAndDrain();
      await db.transcriptDao.upsert(
        _transcript(
          id: 'tr-de-user',
          language: 'de',
          source: 'user',
          label: 'German (imported)',
          updatedAt: DateTime.utc(2026, 7, 6, 13),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emissions, isNotEmpty);
      expect(emissions.last, hasLength(3));
      expect(emissions.last.map((t) => t.id), contains('tr-de-user'));
    });

    test('re-emits when an existing track row updates its label', () async {
      await wireAndDrain();
      await db.transcriptDao.upsert(
        _transcript(
          id: 'tr-en-official',
          language: 'en',
          source: 'official',
          label: 'English (official, revised)',
          updatedAt: DateTime.utc(2026, 7, 6, 14),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emissions, isNotEmpty);
      final official = emissions.last.firstWhere(
        (t) => t.id == 'tr-en-official',
      );
      expect(official.label, 'English (official, revised)');
    });

    test(
      'skips the echo-session-active-id flip when the track list is unchanged',
      () async {
        await wireAndDrain();
        // Active-id flip alone does not change the visible track list.
        // (Whether the consumer downstream cares about the active id is
        // a separate question — handled by `activeTranscriptIdProvider`.)
        await (db.update(
          db.echoSessions,
        )..where((s) => s.id.equals('echo-tracks-dedupe'))).write(
          EchoSessionsCompanion(
            transcriptId: const Value('tr-ja-auto'),
            updatedAt: Value(DateTime.utc(2026, 7, 6, 15)),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(
          emissions,
          isEmpty,
          reason:
              'Echo session active-id flip does not change the track '
              'list. Got $emissions',
        );
      },
    );

    test('re-emits when an existing track is deleted', () async {
      await wireAndDrain();
      await db.transcriptDao.deleteId('tr-ja-auto');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emissions, isNotEmpty);
      expect(emissions.last, hasLength(1));
      expect(emissions.last.single.id, 'tr-en-official');
    });
  });

  group('stream_distinct integration', () {
    test('Stream.distinctBy reuses StreamDistinctExt behavior', () async {
      // Sanity: the shared extension still produces a value-equal-then-skip
      // stream — protects against accidentally swapping the import or the
      // helper for an upstream version that breaks semantics.
      final values = <int>[1, 1, 2, 2, 3, 3, 1];
      final seen = <int>[];
      await for (final v in Stream.fromIterable(
        values,
      ).distinctBy((a, b) => a == b)) {
        seen.add(v);
      }
      expect(seen, [1, 2, 3, 1]);
    });
  });
}
