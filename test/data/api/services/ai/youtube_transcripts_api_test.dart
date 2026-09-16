import 'dart:convert';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';

void main() {
  /// Subscribes to a single named logger for the lifetime of the test and
  /// returns the recorded-log list. Cancellation is registered through the
  /// test's tearDown so the helper does not leak an uncancelled
  /// [StreamSubscription] (lint: `cancel_subscriptions`).
  ///
  /// Without this capture the new WARNING/INFO emissions from
  /// [YoutubeTranscriptsApi] are swallowed by [setupAppLogging] (which is
  /// not called from unit tests) and we cannot assert observability.
  List<LogRecord> captureLogs(String name) {
    final records = <LogRecord>[];
    final sub = Logger(name).onRecord.listen(records.add);
    addTearDown(sub.cancel);
    return records;
  }

  ApiClient apiClient(http.Client client) => ApiClient(
    httpClient: client,
    getBaseUrl: () async => 'https://worker.example.com',
    getAccessToken: () async => 'tok',
  );

  group('YoutubeTranscriptsApi', () {
    group('getCachedTranscript', () {
      test('sends GET with query params', () async {
        http.Request? captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'videoId': 'abc12345678',
              'language': 'en',
              'source': 'official',
              'timeline': [
                {'text': 'Hello', 'start': 0, 'duration': 3000},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.getCachedTranscript(
          videoId: 'abc12345678',
          language: 'en',
        );

        expect(captured, isNotNull);
        expect(captured!.method, 'GET');
        expect(captured!.url.queryParameters['video_id'], 'abc12345678');
        expect(captured!.url.queryParameters['language'], 'en');
        expect(result, isNotNull);
        expect(result!['videoId'], 'abc12345678');
      });

      test('returns null on error', () async {
        final logs = captureLogs('YouTubeTranscripts');

        final mock = MockClient((request) async {
          return http.Response('not found', 404);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.getCachedTranscript(
          videoId: 'abc12345678',
          language: 'en',
        );

        expect(result, isNull);
        // Operators need to see the transport failure so they can distinguish
        // a worker outage from a 404 cache miss.
        expect(
          logs.any(
            (r) => r.level == Level.WARNING && r.message.contains('GET'),
          ),
          isTrue,
        );
      });
    });

    group('uploadTranscript', () {
      test('sends POST with full worker-validated body (format, '
          'caption_fetch, generated_at, video_id, language, source, '
          'timeline, metadata)', () async {
        http.Request? captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'cached': true}),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.uploadTranscript(
          videoId: 'abc12345678',
          language: 'en',
          source: 'official',
          timeline: [
            {'text': 'Hello', 'start': 0, 'duration': 3000},
          ],
          metadata: {'title': 'Test Video'},
        );

        expect(result, isTrue);
        expect(captured, isNotNull);
        final body = jsonDecode(captured!.body) as Map<String, dynamic>;
        expect(body['format'], 'enjoy');
        expect(body['video_id'], 'abc12345678');
        expect(body['language'], 'en');
        expect(body['caption_fetch'], 'official');
        expect(body['source'], 'official');
        expect(body['timeline'], isA<List>());
        expect(body['metadata']['title'], 'Test Video');
        expect(body['generated_at'], isA<String>());
        expect(
          DateTime.parse(body['generated_at'] as String).isUtc,
          isTrue,
          reason: 'generated_at must be an ISO 8601 UTC string',
        );
      });

      test('maps non-official source to caption_fetch=auto', () async {
        http.Request? captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'cached': true}), 201);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.uploadTranscript(
          videoId: 'abc12345678',
          language: 'en',
          source: 'ai',
          timeline: [
            {'text': 'Hello', 'start': 0, 'duration': 3000},
          ],
        );

        expect(result, isTrue);
        final body = jsonDecode(captured!.body) as Map<String, dynamic>;
        expect(body['caption_fetch'], 'auto');
        expect(body['source'], 'ai');
      });

      test('returns false on error', () async {
        final logs = captureLogs('YouTubeTranscripts');

        final mock = MockClient((request) async {
          return http.Response('error', 500);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.uploadTranscript(
          videoId: 'abc12345678',
          language: 'en',
          source: 'official',
          timeline: [
            {'text': 'Hello', 'start': 0, 'duration': 3000},
          ],
        );

        expect(result, isFalse);
        // The cache-warming upload must NOT be a silent failure: a warning
        // carrying the video id + language + line count is what lets an
        // operator correlate a "no captions on Android" report with a
        // failed Windows-side worker upload.
        expect(
          logs.any(
            (r) =>
                r.level == Level.WARNING &&
                r.message.contains('worker upload failed') &&
                r.message.contains('abc12345678') &&
                r.message.contains('en') &&
                r.message.contains('source=official'),
          ),
          isTrue,
        );
      });

      test(
        'treats 409 as success — replay of an already-cached upload',
        () async {
          // Issue #717 review followup (F2): the worker treats a replayed
          // upload as idempotent and replies 409 when the transcript is
          // already cached. Without the explicit 409 branch the durable
          // retry stays queued and exhausts its retries even though the
          // worker already has the transcript.
          final logs = captureLogs('YouTubeTranscripts');

          final mock = MockClient((request) async {
            return http.Response(
              jsonEncode({'error': 'already cached'}),
              409,
              headers: {'content-type': 'application/json'},
            );
          });

          final api = YoutubeTranscriptsApi(apiClient(mock));
          final result = await api.uploadTranscript(
            videoId: 'abc12345678',
            language: 'en',
            source: 'official',
            timeline: [
              {'text': 'Hello', 'start': 0, 'duration': 3000},
            ],
          );

          expect(result, isTrue, reason: '409 must clear the retry queue');
          // Operators should see the replay path, but at INFO (not WARNING
          // — the cache is in the desired state, the retry succeeded).
          expect(
            logs.any(
              (r) =>
                  r.message.contains('409') &&
                  r.message.contains('abc12345678') &&
                  r.message.contains('en'),
            ),
            isTrue,
          );
          // No warning — 409 is not a failure.
          expect(
            logs.any(
              (r) =>
                  r.level == Level.WARNING &&
                  r.message.contains('worker upload failed'),
            ),
            isFalse,
          );
        },
      );

      test('still maps 4xx other than 409 to false', () async {
        final logs = captureLogs('YouTubeTranscripts');

        final mock = MockClient((request) async {
          return http.Response(
            jsonEncode({'error': 'bad timeline'}),
            400,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.uploadTranscript(
          videoId: 'abc12345678',
          language: 'en',
          source: 'official',
          timeline: [
            {'text': 'Hello', 'start': 0, 'duration': 3000},
          ],
        );

        expect(result, isFalse);
        // 400 is a real validation failure — warning must still fire
        // so operators see the "Android cache miss" root cause.
        expect(
          logs.any(
            (r) =>
                r.level == Level.WARNING &&
                r.message.contains('worker upload failed'),
          ),
          isTrue,
        );
      });
    });

    group('fetchClientProfiles', () {
      test('extracts the profiles list from the worker envelope', () async {
        final mock = MockClient((request) async {
          // Wire format matches worker contracts/api.md (snake_case).
          return http.Response(
            jsonEncode({
              'version': '2026-07-12',
              'profiles': [
                {
                  'name': 'IOS',
                  'version': '20.12.1',
                  'client_name_header': '5',
                  'user_agent': 'ua',
                  'context': <String, String>{},
                },
                {
                  'name': 'WEB',
                  'version': '2.20250709.00.00',
                  'client_name_header': '1',
                  'user_agent': 'ua',
                  'context': <String, String>{},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final profiles = await api.fetchClientProfiles();
        expect(profiles, hasLength(2));
        // ApiClient converts snake_case → camelCase.
        expect(profiles[0]['name'], 'IOS');
        expect(profiles[0]['version'], '20.12.1');
        expect(profiles[0]['clientNameHeader'], '5');
        expect(profiles[0]['userAgent'], 'ua');
        expect(profiles[1]['name'], 'WEB');
      });

      test('returns empty list when envelope lacks profiles', () async {
        final mock = MockClient((request) async {
          return http.Response(jsonEncode({'version': '2026-07-12'}), 200);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final profiles = await api.fetchClientProfiles();
        expect(profiles, isEmpty);
      });

      test('returns empty list on transport error', () async {
        final logs = captureLogs('YouTubeTranscripts');

        final mock = MockClient((request) async {
          return http.Response('error', 500);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final profiles = await api.fetchClientProfiles();
        expect(profiles, isEmpty);
        // Same rationale as the two previous cases: the InnerTube profiles
        // fallback chain depends on visibility here.
        expect(
          logs.any(
            (r) =>
                r.level == Level.WARNING && r.message.contains('profile fetch'),
          ),
          isTrue,
        );
      });
    });
  });
}
