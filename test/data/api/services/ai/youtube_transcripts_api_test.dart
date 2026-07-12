import 'dart:convert';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
        final mock = MockClient((request) async {
          return http.Response('not found', 404);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final result = await api.getCachedTranscript(
          videoId: 'abc12345678',
          language: 'en',
        );

        expect(result, isNull);
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
      });
    });

    group('fetchClientProfiles', () {
      test('extracts the profiles list from the worker envelope', () async {
        final mock = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'version': '2026-07-12',
              'profiles': [
                {
                  'name': 'ios',
                  'clientName': 'IOS',
                  'clientVersion': '20.12.1',
                  'clientNameHeader': '5',
                  'userAgent': 'ua',
                  'context': <String, String>{},
                },
                {
                  'name': 'web',
                  'clientName': 'WEB',
                  'clientVersion': '2.20250709.00.00',
                  'clientNameHeader': '1',
                  'userAgent': 'ua',
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
        expect(profiles[0]['name'], 'ios');
        expect(profiles[1]['name'], 'web');
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
        final mock = MockClient((request) async {
          return http.Response('error', 500);
        });

        final api = YoutubeTranscriptsApi(apiClient(mock));
        final profiles = await api.fetchClientProfiles();
        expect(profiles, isEmpty);
      });
    });
  });
}
