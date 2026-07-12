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
    test('pollTranscript posts single-language body as snake_case', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'status': 'ready'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = YoutubeTranscriptsApi(apiClient(mock));
      await api.pollTranscript(
        videoId: 'dQw4w9WgXcQ',
        language: 'en',
        captionFetch: 'auto',
        forceRefresh: true,
        waitMs: 20000,
      );

      expect(captured, isNotNull);
      final req = captured!;
      expect(req.url.path, '/youtube/transcripts');
      expect(req.method, 'POST');

      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['video_id'], 'dQw4w9WgXcQ');
      expect(body['language'], 'en');
      expect(body['caption_fetch'], 'auto');
      expect(body['force_refresh'], true);
      expect(body['wait_ms'], 20000);
      expect(body.containsKey('languages'), isFalse);
    });

    test('pollTranscripts posts multi-language body as snake_case', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'status': 'ready',
            'transcripts': <Map<String, dynamic>>[],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = YoutubeTranscriptsApi(apiClient(mock));
      await api.pollTranscripts(
        videoId: 'dQw4w9WgXcQ',
        languages: const ['en', 'zh'],
        captionFetch: 'auto',
        forceRefresh: false,
        waitMs: 20000,
      );

      expect(captured, isNotNull);
      final req = captured!;
      expect(req.url.path, '/youtube/transcripts');

      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['video_id'], 'dQw4w9WgXcQ');
      expect(body['languages'], ['en', 'zh']);
      expect(body['caption_fetch'], 'auto');
      expect(body['force_refresh'], false);
      expect(body['wait_ms'], 20000);
      expect(body.containsKey('language'), isFalse);
    });

    test('pollTranscripts omits nullable fields when not supplied', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'status': 'ready'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = YoutubeTranscriptsApi(apiClient(mock));
      await api.pollTranscripts(
        videoId: 'dQw4w9WgXcQ',
        languages: const ['en'],
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['video_id'], 'dQw4w9WgXcQ');
      expect(body['languages'], ['en']);
      expect(body.containsKey('caption_fetch'), isFalse);
      expect(body.containsKey('force_refresh'), isFalse);
      expect(body.containsKey('wait_ms'), isFalse);
    });
  });

  group('YoutubeTranscriptsApi cache methods', () {
    test('getCachedTranscript sends GET with query params', () async {
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

    test('getCachedTranscript returns null on error', () async {
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

    test('uploadTranscript sends POST with transcript body', () async {
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
      expect(body['video_id'], 'abc12345678');
      expect(body['language'], 'en');
      expect(body['source'], 'official');
      expect(body['timeline'], isA<List>());
      expect(body['metadata']['title'], 'Test Video');
    });

    test('uploadTranscript returns false on error', () async {
      final mock = MockClient((request) async {
        return http.Response('error', 500);
      });

      final api = YoutubeTranscriptsApi(apiClient(mock));
      final result = await api.uploadTranscript(
        videoId: 'abc12345678',
        language: 'en',
        source: 'official',
        timeline: [],
      );

      expect(result, isFalse);
    });

    test('fetchClientProfiles returns profile list', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'name': 'ios',
              'clientName': 'IOS',
              'clientVersion': '1.0',
              'clientNameHeader': '5',
              'userAgent': 'ua',
              'context': <String, String>{},
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = YoutubeTranscriptsApi(apiClient(mock));
      final profiles = await api.fetchClientProfiles();
      expect(profiles.length, 1);
      expect(profiles[0]['name'], 'ios');
    });

    test('fetchClientProfiles returns empty list on error', () async {
      final mock = MockClient((request) async {
        return http.Response('error', 500);
      });

      final api = YoutubeTranscriptsApi(apiClient(mock));
      final profiles = await api.fetchClientProfiles();
      expect(profiles, isEmpty);
    });
  });
}
