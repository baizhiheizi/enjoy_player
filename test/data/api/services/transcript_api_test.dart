import 'dart:convert';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/transcript_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClient mock) => ApiClient(
  httpClient: mock,
  getBaseUrl: () async => 'https://enjoy.example.com',
  getAccessToken: () async => 'tok',
);

Map<String, dynamic> _decode(String body) =>
    Map<String, dynamic>.from(jsonDecode(body) as Map);

void main() {
  group('TranscriptApi.transcripts', () {
    test(
      'forwards targetId, targetType, source, and language as query params',
      () async {
        http.Request? captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response('[]', 200);
        });

        await TranscriptApi(_client(mock)).transcripts(
          targetId: 'vid-1',
          targetType: 'Video',
          source: 'cloud',
          language: 'en',
        );

        expect(captured!.url.path, '/api/v1/transcripts');
        final qp = captured!.url.queryParameters;
        expect(qp['target_id'], 'vid-1');
        expect(qp['target_type'], 'Video');
        expect(qp['source'], 'cloud');
        expect(qp['language'], 'en');
      },
    );

    test('returns parsed JSON list', () async {
      final mock = MockClient((_) async {
        return http.Response(
          '[{"id": "t1"}, {"id": "t2"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final list = await TranscriptApi(_client(mock)).transcripts();
      expect(list, hasLength(2));
      expect(list.first['id'], 't1');
    });

    test('omits query params when arguments are null', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      });

      await TranscriptApi(_client(mock)).transcripts();
      expect(captured!.url.queryParameters, isEmpty);
    });
  });

  group('TranscriptApi.transcript', () {
    test('builds the per-resource path under /transcripts', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('{"id": "t1"}', 200);
      });

      final json = await TranscriptApi(_client(mock)).transcript('t1');
      expect(captured!.url.path, '/api/v1/transcripts/t1');
      expect(json['id'], 't1');
    });
  });

  group('TranscriptApi.uploadTranscript', () {
    test('wraps the body under "transcript" and POSTs', () async {
      Map<String, dynamic>? sentBody;
      http.BaseRequest? captured;
      final mock = MockClient((request) async {
        captured = request;
        sentBody = _decode(request.body);
        return http.Response('{"transcript": {"id": "t1"}}', 200);
      });

      final out = await TranscriptApi(
        _client(mock),
      ).uploadTranscript(<String, dynamic>{'id': 't1'});
      expect(captured, isA<http.Request>());
      expect(captured!.method, 'POST');
      expect(sentBody, isNotNull);
      expect(sentBody!.containsKey('transcript'), isTrue);
      expect(out['transcript'], isA<Map>());
    });
  });
}
