import 'dart:convert';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
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
  group('AudioApi.audios', () {
    test('forwards provider, limit and updatedAfter as query params', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      });

      await AudioApi(_client(mock)).audios(
        provider: 'local',
        limit: 10,
        updatedAfter: '2026-01-01T00:00:00.000Z',
      );

      expect(captured!.url.path, '/api/v1/mine/audios');
      final qp = captured!.url.queryParameters;
      expect(qp['provider'], 'local');
      expect(qp['limit'], '10');
      expect(qp['updated_after'], '2026-01-01T00:00:00.000Z');
    });

    test('returns parsed JSON list', () async {
      final mock = MockClient((_) async {
        return http.Response(
          '[{"id": "a1"}, {"id": "a2"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final list = await AudioApi(_client(mock)).audios();
      expect(list, hasLength(2));
      expect(list.first['id'], 'a1');
    });

    test('omits query params when arguments are null', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      });

      await AudioApi(_client(mock)).audios();
      expect(captured!.url.queryParameters, isEmpty);
    });
  });

  group('AudioApi.audio', () {
    test('builds the per-resource path under /mine/audios', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('{"id": "a1"}', 200);
      });

      final json = await AudioApi(_client(mock)).audio('a1');
      expect(captured!.url.path, '/api/v1/mine/audios/a1');
      expect(json['id'], 'a1');
    });
  });

  group('AudioApi.uploadAudio', () {
    test('wraps the body under "audio" and POSTs', () async {
      Map<String, dynamic>? sentBody;
      http.BaseRequest? captured;
      final mock = MockClient((request) async {
        captured = request;
        sentBody = _decode(request.body);
        return http.Response('{"audio": {"id": "a1"}}', 200);
      });

      final out = await AudioApi(
        _client(mock),
      ).uploadAudio(<String, dynamic>{'id': 'a1'});
      expect(captured, isA<http.Request>());
      expect(captured!.method, 'POST');
      expect(sentBody, isNotNull);
      expect(sentBody!.containsKey('audio'), isTrue);
      expect(out['audio'], isA<Map>());
    });
  });

  group('AudioApi.deleteAudio', () {
    test('issues DELETE to /mine/audios/:id', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('{"status": "ok"}', 200);
      });

      await AudioApi(_client(mock)).deleteAudio('a1');
      expect(captured!.url.path, '/api/v1/mine/audios/a1');
      expect(captured!.method, 'DELETE');
    });
  });
}
