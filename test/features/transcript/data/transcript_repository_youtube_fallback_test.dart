/// Unit tests for the YouTube fallback chain in `TranscriptRepository`.
///
/// Covers:
///   * F1 — Tier 2 (direct InnerTube) runs even when `videos.language` is
///     `und` / empty; Tier 1 (worker cache) is skipped in that case.
///   * F2 — Language-aware primary picker: video language wins over
///     learning language wins over source priority.
///   * F3 — Failed worker upload enqueues a durable sync_queue retry row.
///   * F4 — YoutubeCaptionFetcher timedtext GET carries the profile UA
///     and a Referer header.
///
/// Each test uses a unique `mediaId` so cross-test row leakage from the
/// shared `NativeDatabase.memory()` executor cannot affect assertions.
library;

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/client_profile.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/data/youtube_caption_fetcher.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTranscriptsApi implements YoutubeTranscriptsClient {
  _FakeTranscriptsApi({
    Map<String, Map<String, dynamic>>? cacheHits,
    this.uploadShouldFail = false,
  }) : cacheHits = cacheHits ?? <String, Map<String, dynamic>>{};

  final Map<String, Map<String, dynamic>> cacheHits;
  bool uploadShouldFail;

  final List<({String videoId, String language, String source, int lineCount})>
  uploads = [];

  @override
  Future<Map<String, dynamic>?> getCachedTranscript({
    required String videoId,
    required String language,
  }) async {
    final key = '$videoId/$language';
    return cacheHits[key];
  }

  @override
  Future<bool> uploadTranscript({
    required String videoId,
    required String language,
    required String source,
    required List<Map<String, dynamic>> timeline,
    Map<String, dynamic>? metadata,
  }) async {
    uploads.add((
      videoId: videoId,
      language: language,
      source: source,
      lineCount: timeline.length,
    ));
    return !uploadShouldFail;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchClientProfiles() async =>
      <Map<String, dynamic>>[];
}

class _StubYoutubeCaptionFetcher extends YoutubeCaptionFetcher {
  _StubYoutubeCaptionFetcher({required AllCaptionsResult result})
    : _nextResult = result,
      super(httpClient: http.Client(), profiles: kBuiltInClientProfiles);

  final AllCaptionsResult _nextResult;
  int calls = 0;
  String? lastPreferredLang;

  @override
  Future<AllCaptionsResult> fetchAllSubtitles({
    required String videoId,
    String preferredLang = 'en',
  }) async {
    calls++;
    lastPreferredLang = preferredLang;
    return _nextResult;
  }
}

VideoRow _video({required String id, String language = 'en-US'}) {
  final now = DateTime.utc(2026, 7, 14);
  return VideoRow(
    id: id,
    vid: 'tIgO_Sjh3tQ',
    provider: 'youtube',
    title: 't',
    description: null,
    thumbnailUrl: null,
    durationSeconds: 0,
    language: language,
    source: 'youtube',
    localUri: null,
    md5: null,
    size: 0,
    mediaUrl: 'https://www.youtube.com/watch?v=tIgO_Sjh3tQ',
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

CaptionFetchResult _track({
  required String language,
  String source = 'official',
  String text = 'hello',
}) {
  return CaptionFetchResult(
    subtitles: [TranscriptLine(text: text, startMs: 0, durationMs: 1000)],
    source: source,
    language: language,
    fetchProfile: 'ios',
  );
}

Future<void> _drain() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<List<SyncQueueRow>> _waitForQueue(AppDatabase db) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  List<SyncQueueRow> queued = const [];
  while (queued.isEmpty && DateTime.now().isBefore(deadline)) {
    queued = await db.syncQueueDao.peekBatch();
    if (queued.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
  return queued;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('_fetchYoutubeTranscriptsWithFallback', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('F1: Tier 2 still runs when videos.language is "und"', () async {
      const mediaId = 'v-und';
      await db.videoDao.insertRow(_video(id: mediaId, language: 'und'));
      final api = _FakeTranscriptsApi();
      final fetcher = _StubYoutubeCaptionFetcher(
        result: AllCaptionsResult(
          results: [
            _track(language: 'en', text: 'en'),
            _track(language: 'es', text: 'es'),
          ],
        ),
      );
      final repo = TranscriptRepository(db, null, api, fetcher);

      final result = await repo.fetchCloudTranscripts(mediaId, force: true);
      expect(result.status, TranscriptCloudFetchStatus.success);
      expect(result.storedCount, 2);
      expect(fetcher.calls, 1);
      expect(fetcher.lastPreferredLang, '');

      final rows = await db.transcriptDao.listForTarget('Video', mediaId);
      expect(rows.map((r) => r.language).toSet(), {'en', 'es'});
    });

    test('F1: empty language skips Tier 1 worker GET, runs Tier 2', () async {
      const mediaId = 'v-empty';
      await db.videoDao.insertRow(_video(id: mediaId, language: ''));
      final api = _FakeTranscriptsApi();
      final fetcher = _StubYoutubeCaptionFetcher(
        result: AllCaptionsResult(results: [_track(language: 'ja')]),
      );
      final repo = TranscriptRepository(db, null, api, fetcher);

      await repo.fetchCloudTranscripts(mediaId, force: true);

      expect(fetcher.calls, 1);
      expect(fetcher.lastPreferredLang, '');
    });

    test(
      'F2: primary picker prefers video language over learning language',
      () async {
        const mediaId = 'v-pick-video';
        await db.videoDao.insertRow(_video(id: mediaId, language: 'es-ES'));
        final api = _FakeTranscriptsApi();
        final fetcher = _StubYoutubeCaptionFetcher(
          result: AllCaptionsResult(
            results: [
              _track(language: 'en', text: 'en'),
              _track(language: 'es', text: 'es'),
            ],
          ),
        );
        final repo = TranscriptRepository(db, null, api, fetcher);

        await repo.fetchCloudTranscripts(
          mediaId,
          force: true,
          learningLanguage: 'en-US',
        );

        final session = await db.echoSessionDao.getLatestForTarget(
          'Video',
          mediaId,
        );
        expect(session?.transcriptId, isNotNull);
        final rows = await db.transcriptDao.listForTarget('Video', mediaId);
        final picked = rows.firstWhere((r) => r.id == session!.transcriptId);
        expect(picked.language, 'es');
      },
    );

    test(
      'F2: primary picker falls back to learning language when no video match',
      () async {
        const mediaId = 'v-pick-learn';
        // Video language is intentionally one with no broad-match tracks.
        await db.videoDao.insertRow(_video(id: mediaId, language: 'ko-KR'));
        final api = _FakeTranscriptsApi();
        final fetcher = _StubYoutubeCaptionFetcher(
          result: AllCaptionsResult(
            results: [
              _track(language: 'fr', text: 'fr'),
              _track(language: 'en', text: 'en'),
              _track(language: 'de', text: 'de'),
            ],
          ),
        );
        final repo = TranscriptRepository(db, null, api, fetcher);

        await repo.fetchCloudTranscripts(
          mediaId,
          force: true,
          learningLanguage: 'en-US',
        );

        final session = await db.echoSessionDao.getLatestForTarget(
          'Video',
          mediaId,
        );
        final rows = await db.transcriptDao.listForTarget('Video', mediaId);
        final picked = rows.firstWhere((r) => r.id == session!.transcriptId);
        expect(picked.language, 'en');
      },
    );

    test(
      'F2: primary picker falls back to source priority when no language match',
      () async {
        const mediaId = 'v-pick-source';
        await db.videoDao.insertRow(_video(id: mediaId, language: 'ko-KR'));
        final api = _FakeTranscriptsApi();
        final fetcher = _StubYoutubeCaptionFetcher(
          result: AllCaptionsResult(
            results: [
              _track(language: 'fr', text: 'fr', source: 'user'),
              _track(language: 'ja', text: 'ja', source: 'official'),
            ],
          ),
        );
        final repo = TranscriptRepository(db, null, api, fetcher);

        await repo.fetchCloudTranscripts(
          mediaId,
          force: true,
          learningLanguage: 'de-DE',
        );

        final session = await db.echoSessionDao.getLatestForTarget(
          'Video',
          mediaId,
        );
        final rows = await db.transcriptDao.listForTarget('Video', mediaId);
        final picked = rows.firstWhere((r) => r.id == session!.transcriptId);
        expect(picked.language, 'ja');
      },
    );

    test(
      'F2: existing user-picked primary is preserved over language picker',
      () async {
        const mediaId = 'v-user-pick';
        await db.videoDao.insertRow(_video(id: mediaId, language: 'es-ES'));
        final api = _FakeTranscriptsApi();
        final fetcher = _StubYoutubeCaptionFetcher(
          result: AllCaptionsResult(
            results: [
              _track(language: 'es'),
              _track(language: 'en'),
            ],
          ),
        );
        final repo = TranscriptRepository(db, null, api, fetcher);

        await repo.importSubtitle(
          mediaId: mediaId,
          file: XFile.fromData(
            utf8.encode('1\n00:00:00,000 --> 00:00:01,000\nHello'),
            name: 'clip.en.srt',
          ),
          language: 'en',
          label: 'manual en',
        );

        final before = await db.echoSessionDao.getLatestForTarget(
          'Video',
          mediaId,
        );
        expect(before?.transcriptId, isNotNull);

        await repo.fetchCloudTranscripts(mediaId, force: true);

        final after = await db.echoSessionDao.getLatestForTarget(
          'Video',
          mediaId,
        );
        expect(after?.transcriptId, before?.transcriptId);
      },
    );

    test('F3: failed worker upload enqueues a sync_queue retry row', () async {
      const mediaId = 'v-retry';
      await db.videoDao.insertRow(_video(id: mediaId, language: 'en-US'));
      final api = _FakeTranscriptsApi(uploadShouldFail: true);
      final fetcher = _StubYoutubeCaptionFetcher(
        result: AllCaptionsResult(results: [_track(language: 'en')]),
      );
      final repo = TranscriptRepository(db, null, api, fetcher);

      await repo.fetchCloudTranscripts(mediaId, force: true);
      await _drain();

      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (api.uploads.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(api.uploads, hasLength(1));

      final queued = await _waitForQueue(db);
      expect(queued, hasLength(1));
      final payload = jsonDecode(queued.single.payloadJson!);
      expect(payload['kind'], 'youtube_upload');
      expect(payload['videoId'], 'tIgO_Sjh3tQ');
      expect(payload['language'], 'en');
    });

    test(
      'F3: empty InnerTube result skips upload retry (nothing to enqueue)',
      () async {
        const mediaId = 'v-empty-t2';
        await db.videoDao.insertRow(_video(id: mediaId, language: 'en-US'));
        final api = _FakeTranscriptsApi(uploadShouldFail: true);
        final fetcher = _StubYoutubeCaptionFetcher(
          result: const AllCaptionsResult(results: []),
        );
        final repo = TranscriptRepository(db, null, api, fetcher);

        await repo.fetchCloudTranscripts(mediaId, force: true);
        await _drain();

        final queuedAll = await db.syncQueueDao.peekBatch(limit: 1000);
        final queued = queuedAll
            .where((r) => r.entityId.startsWith('$mediaId/'))
            .toList();
        expect(queued, isEmpty);
        expect(api.uploads, isEmpty);
      },
    );
  });

  group('YoutubeCaptionFetcher timedtext UA', () {
    test('F4: timedtext GET sends the profile UA + Referer header', () async {
      const captionUrl = 'https://www.youtube.com/api/timedtext?v=test&lang=en';
      String? capturedUserAgent;
      String? capturedReferer;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'playabilityStatus': {'status': 'OK'},
              'captions': {
                'playerCaptionsTracklistRenderer': {
                  'captionTracks': [
                    {
                      'baseUrl': captionUrl,
                      'vssId': '.en',
                      'languageCode': 'en',
                    },
                  ],
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        capturedUserAgent = request.headers['user-agent'];
        capturedReferer = request.headers['referer'];
        return http.Response(
          jsonEncode({
            'events': [
              {
                'tStartMs': 0,
                'dDurationMs': 1000,
                'segs': [
                  {'utf8': 'hi'},
                ],
                'aAppend': 0,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final fetcher = YoutubeCaptionFetcher(
        httpClient: mockClient,
        profiles: kBuiltInClientProfiles,
      );
      final result = await fetcher.fetchSubtitles(
        videoId: 'test1234567',
        lang: 'en',
      );
      expect(result.isSuccess, isTrue);

      expect(capturedUserAgent, isNotNull);
      expect(capturedUserAgent, contains('com.google.ios.youtube'));
      expect(capturedReferer, 'https://m.youtube.com/');
    });
  });
}
