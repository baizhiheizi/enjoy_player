import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/api/services/transcript_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TranscriptRepository', () {
    late AppDatabase db;
    late TranscriptRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
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

    test(
      'setActiveTranscript and setSecondaryTranscript update session',
      () async {
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
        final timelineJson = jsonEncode([
          const TranscriptLine(text: 'x', startMs: 0, durationMs: 100).toJson(),
        ]);

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
      },
    );

    test(
      'deleteTranscript clears secondary when session referenced deleted id',
      () async {
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

        final primaryJson = jsonEncode([
          const TranscriptLine(text: 'a', startMs: 0, durationMs: 100).toJson(),
        ]);
        final secondaryJson = jsonEncode([
          const TranscriptLine(text: 'b', startMs: 0, durationMs: 100).toJson(),
        ]);

        await db.transcriptDao.upsert(
          TranscriptRow(
            id: 'tr-primary',
            targetType: 'Audio',
            targetId: 'm1',
            language: 'en',
            source: 'user',
            timelineJson: primaryJson,
            referenceId: null,
            label: 'Primary',
            trackIndex: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.transcriptDao.upsert(
          TranscriptRow(
            id: 'tr-secondary',
            targetType: 'Audio',
            targetId: 'm1',
            language: 'es',
            source: 'user',
            timelineJson: secondaryJson,
            referenceId: null,
            label: 'Secondary',
            trackIndex: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        );

        await repo.setActiveTranscript('m1', 'tr-primary');
        await repo.setSecondaryTranscript('m1', 'tr-secondary');

        await repo.deleteTranscript('tr-secondary');

        final row = await db.transcriptDao.getById('tr-secondary');
        expect(row, isNull);

        final s = await db.echoSessionDao.getLatestForTarget('Audio', 'm1');
        expect(s?.transcriptId, 'tr-primary');
        expect(s?.secondaryTranscriptId, isNull);
      },
    );

    test(
      'deleteTranscript reassigns primary to next track when primary deleted',
      () async {
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

        final jsonA = jsonEncode([
          const TranscriptLine(text: 'a', startMs: 0, durationMs: 100).toJson(),
        ]);
        final jsonB = jsonEncode([
          const TranscriptLine(text: 'b', startMs: 0, durationMs: 100).toJson(),
        ]);

        await db.transcriptDao.upsert(
          TranscriptRow(
            id: 'tr-embedded',
            targetType: 'Audio',
            targetId: 'm1',
            language: 'en',
            source: 'official',
            timelineJson: jsonA,
            referenceId: null,
            label: 'Embedded',
            trackIndex: 0,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.transcriptDao.upsert(
          TranscriptRow(
            id: 'tr-imported',
            targetType: 'Audio',
            targetId: 'm1',
            language: 'und',
            source: 'user',
            timelineJson: jsonB,
            referenceId: null,
            label: 'Imported',
            trackIndex: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        );

        await repo.setActiveTranscript('m1', 'tr-imported');
        await repo.setSecondaryTranscript('m1', null);

        await repo.deleteTranscript('tr-imported');

        final s = await db.echoSessionDao.getLatestForTarget('Audio', 'm1');
        expect(s?.transcriptId, 'tr-embedded');
        expect(s?.secondaryTranscriptId, isNull);
      },
    );

    test(
      'deleteTranscript clears secondary when new primary collides with it',
      () async {
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

        final jsonA = jsonEncode([
          const TranscriptLine(text: 'a', startMs: 0, durationMs: 100).toJson(),
        ]);
        final jsonB = jsonEncode([
          const TranscriptLine(text: 'b', startMs: 0, durationMs: 100).toJson(),
        ]);

        await db.transcriptDao.upsert(
          TranscriptRow(
            id: 'tr-embedded',
            targetType: 'Audio',
            targetId: 'm1',
            language: 'en',
            source: 'official',
            timelineJson: jsonA,
            referenceId: null,
            label: 'Embedded',
            trackIndex: 0,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.transcriptDao.upsert(
          TranscriptRow(
            id: 'tr-imported',
            targetType: 'Audio',
            targetId: 'm1',
            language: 'und',
            source: 'user',
            timelineJson: jsonB,
            referenceId: null,
            label: 'Imported',
            trackIndex: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        );

        await repo.setActiveTranscript('m1', 'tr-imported');
        await repo.setSecondaryTranscript('m1', 'tr-embedded');

        await repo.deleteTranscript('tr-imported');

        final s = await db.echoSessionDao.getLatestForTarget('Audio', 'm1');
        expect(s?.transcriptId, 'tr-embedded');
        expect(s?.secondaryTranscriptId, isNull);
      },
    );
  });

  group('fetchCloudTranscripts', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> insertYoutubeVideo({
      required String mediaId,
      required String vid,
      String language = 'und',
    }) async {
      final now = DateTime.now();
      await db.videoDao.insertRow(
        VideoRow(
          id: mediaId,
          vid: vid,
          provider: 'youtube',
          title: 'Test',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: language,
          source: 'youtube',
          localUri: null,
          md5: null,
          size: null,
          mediaUrl: 'https://www.youtube.com/watch?v=$vid',
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('YouTube worker skips fetch when media language is und', () async {
      const vid = 'abcdefghijk';
      final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
      await insertYoutubeVideo(mediaId: mediaId, vid: vid);

      final client = _CapturingYoutubeClient(
        response: {
          'status': 'ready',
          'language': 'en',
          'source': 'official',
          'timeline': [
            {'text': 'a', 'start': 1000, 'duration': 200},
          ],
        },
      );
      final repo = TranscriptRepository(db, null, client);
      final result = await repo.resolveOnOpen(mediaId, fetchCloud: true);

      expect(result.cloud.status, TranscriptCloudFetchStatus.skipped);
      expect(client.lastVideoId, isNull);
    });

    test('YouTube worker uses media language base for captions', () async {
      const vid = 'abcdefghijk';
      final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
      await insertYoutubeVideo(mediaId: mediaId, vid: vid, language: 'ja-JP');

      final client = _CapturingYoutubeClient(
        response: {
          'status': 'ready',
          'language': 'ja',
          'source': 'official',
          'timeline': [
            {'text': 'a', 'start': 1000, 'duration': 200},
          ],
        },
      );
      final repo = TranscriptRepository(db, null, client);
      final result = await repo.resolveOnOpen(mediaId, fetchCloud: true);

      expect(result.cloud.status, TranscriptCloudFetchStatus.success);
      expect(client.lastLanguage, 'ja');
    });

    test('YouTube worker poll sends videoId equal to VideoRow.vid', () async {
      const vid = 'abcdefghijk';
      final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
      await insertYoutubeVideo(mediaId: mediaId, vid: vid, language: 'en');

      final client = _CapturingYoutubeClient(
        response: {
          'status': 'ready',
          'language': 'en',
          'source': 'official',
          'timeline': [
            {'text': 'a', 'start': 1000, 'duration': 200},
          ],
          'metadata': {'title': 'VT'},
        },
      );
      final repo = TranscriptRepository(db, null, client);
      final result = await repo.resolveOnOpen(mediaId, fetchCloud: true);

      expect(result.cloud.status, TranscriptCloudFetchStatus.success);

      expect(client.lastVideoId, vid);
      expect(client.lastVideoId, isNot(mediaId));

      final tid = enjoyTranscriptId(
        targetType: 'Video',
        targetId: mediaId,
        language: 'en',
        source: 'official',
      );
      final row = await db.transcriptDao.getById(tid);
      expect(row, isNotNull);
      expect(row!.targetType, 'Video');
      expect(row.targetId, mediaId);
      expect(row.label, 'VT');
      expect(repo.linesForRow(row).single.startMs, 1000);
      expect(repo.linesForRow(row).single.durationMs, 200);

      final st = await db.transcriptFetchStateDao.getForTarget(
        'Video',
        mediaId,
      );
      expect(st, isNotNull);
      expect(st!.lastStatus, 'success');
    });

    test(
      'YouTube worker failure returns error without fetch state row',
      () async {
        const vid = 'abcdefghijk';
        final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
        await insertYoutubeVideo(mediaId: mediaId, vid: vid, language: 'en');

        final client = _CapturingYoutubeClient(
          response: {'status': 'failed', 'error': 'no captions'},
        );
        final repo = TranscriptRepository(db, null, client);
        final result = await repo.resolveOnOpen(mediaId, fetchCloud: true);

        expect(result.cloud.status, TranscriptCloudFetchStatus.error);
        final st = await db.transcriptFetchStateDao.getForTarget(
          'Video',
          mediaId,
        );
        expect(st?.lastStatus, 'error');
        expect(st?.lastError, 'no captions');
      },
    );

    test(
      'YouTube generating responses do not record transcript_fetch_states',
      () async {
        const vid = 'abcdefghijk';
        final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
        await insertYoutubeVideo(mediaId: mediaId, vid: vid, language: 'en');

        final client = _SequencedYoutubeClient([
          {
            'status': 'generating',
            'jobId': 'j',
            'stage': 'running',
            'created': true,
          },
          {
            'status': 'generating',
            'jobId': 'j',
            'stage': 'running',
            'created': false,
          },
        ]);
        final repo = TranscriptRepository(db, null, client, 2, Duration.zero);
        final result = await repo.fetchCloudTranscripts(mediaId);

        expect(result.status, TranscriptCloudFetchStatus.error);
        expect(
          await db.transcriptFetchStateDao.getForTarget('Video', mediaId),
          isNull,
        );
      },
    );

    test('non-YouTube uses Rails TranscriptApi', () async {
      final now = DateTime.now();
      await db.audioDao.insertRow(
        AudioRow(
          id: 'audio1',
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

      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final rails = TranscriptApi(
        ApiClient(
          httpClient: mock,
          getBaseUrl: () async => 'https://api.example.com',
          getAccessToken: () async => 'tok',
        ),
      );

      final repo = TranscriptRepository(db, rails, _ThrowingYoutubeClient());
      await repo.fetchCloudTranscripts('audio1');

      expect(captured, isNotNull);
      final uri = captured!.url;
      expect(uri.path, '/api/v1/transcripts');
      expect(uri.queryParameters['target_id'], 'audio1');
      expect(uri.queryParameters['target_type'], 'Audio');
    });

    test('ensurePrimaryTranscript picks highest-priority track', () async {
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

      final timelineJson = jsonEncode([
        const TranscriptLine(text: 'x', startMs: 0, durationMs: 100).toJson(),
      ]);

      await db.transcriptDao.upsert(
        TranscriptRow(
          id: 'tr-user',
          targetType: 'Audio',
          targetId: 'm1',
          language: 'en',
          source: 'user',
          timelineJson: timelineJson,
          referenceId: null,
          label: 'user',
          trackIndex: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.transcriptDao.upsert(
        TranscriptRow(
          id: 'tr-official',
          targetType: 'Audio',
          targetId: 'm1',
          language: 'en',
          source: 'official',
          timelineJson: timelineJson,
          referenceId: null,
          label: 'official',
          trackIndex: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );

      final repo = TranscriptRepository(db);
      final assigned = await repo.ensurePrimaryTranscript('m1');
      expect(assigned, isTrue);

      final session = await db.echoSessionDao.getLatestForTarget('Audio', 'm1');
      expect(session?.transcriptId, 'tr-official');
    });

    test('ensurePrimaryTranscript reassigns stale session transcript id', () async {
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

      final timelineJson = jsonEncode([
        const TranscriptLine(text: 'x', startMs: 0, durationMs: 100).toJson(),
      ]);

      await db.transcriptDao.upsert(
        TranscriptRow(
          id: 'tr-official',
          targetType: 'Audio',
          targetId: 'm1',
          language: 'en',
          source: 'official',
          timelineJson: timelineJson,
          referenceId: null,
          label: 'official',
          trackIndex: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.echoSessionDao.updatePrimaryTranscriptForTarget(
        'Audio',
        'm1',
        'tr-missing',
      );

      final repo = TranscriptRepository(db);
      final assigned = await repo.ensurePrimaryTranscript('m1');
      expect(assigned, isTrue);

      final session = await db.echoSessionDao.getLatestForTarget('Audio', 'm1');
      expect(session?.transcriptId, 'tr-official');
    });

    test(
      'importSidecarSubtitles imports adjacent srt for local media',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'enjoy_repo_sidecar_',
        );
        try {
          final mediaFile = File(p.join(tempDir.path, 'clip.mp3'));
          await mediaFile.writeAsString('audio');
          await File(
            p.join(tempDir.path, 'clip.en.srt'),
          ).writeAsString('1\n00:00:00,000 --> 00:00:01,000\nHello');

          final now = DateTime.now();
          await db.audioDao.insertRow(
            AudioRow(
              id: 'm-sidecar',
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
              localUri: mediaFile.uri.toString(),
              md5: null,
              size: 1,
              mediaUrl: null,
              syncStatus: null,
              serverUpdatedAt: null,
              createdAt: now,
              updatedAt: now,
            ),
          );

          final repo = TranscriptRepository(db);
          final imported = await repo.importSidecarSubtitles('m-sidecar');
          expect(imported, 1);

          final rows = await db.transcriptDao.listForTarget(
            'Audio',
            'm-sidecar',
          );
          expect(rows, hasLength(1));
          expect(rows.single.language, 'en');
        } finally {
          if (tempDir.existsSync()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );
  });
}

class _CapturingYoutubeClient implements YoutubeTranscriptsClient {
  _CapturingYoutubeClient({required this.response});

  final Map<String, dynamic> response;
  String? lastVideoId;
  String? lastLanguage;

  @override
  Future<Map<String, dynamic>> pollTranscript({
    required String videoId,
    required String language,
    String? captionFetch,
    bool? forceRefresh,
  }) async {
    lastVideoId = videoId;
    lastLanguage = language;
    return Map<String, dynamic>.from(response);
  }
}

class _SequencedYoutubeClient implements YoutubeTranscriptsClient {
  _SequencedYoutubeClient(this._responses);

  final List<Map<String, dynamic>> _responses;
  var _i = 0;

  @override
  Future<Map<String, dynamic>> pollTranscript({
    required String videoId,
    required String language,
    String? captionFetch,
    bool? forceRefresh,
  }) async {
    final idx = _i < _responses.length ? _i : _responses.length - 1;
    final m = _responses[idx];
    _i++;
    return Map<String, dynamic>.from(m);
  }
}

class _ThrowingYoutubeClient implements YoutubeTranscriptsClient {
  @override
  Future<Map<String, dynamic>> pollTranscript({
    required String videoId,
    required String language,
    String? captionFetch,
    bool? forceRefresh,
  }) =>
      throw StateError('YouTube client must not be used for non-YouTube media');
}
