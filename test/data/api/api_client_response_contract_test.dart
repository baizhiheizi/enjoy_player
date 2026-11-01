import 'dart:convert';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(
  MockClient mock, {
  String baseUrl = 'https://api.example.com',
}) => ApiClient(
  httpClient: mock,
  getBaseUrl: () async => baseUrl,
  getAccessToken: () async => 'token',
);

void main() {
  group('ApiClient transport variants share one response envelope', () {
    test('putBytesJson decodes a 2xx JSON object body', () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode({'mediaId': 'm1'}), 200),
      );

      final out = await _client(mock).putBytesJson(
        '/audio/media/m1',
        bytes: const [1, 2, 3],
        contentType: 'audio/mpeg',
      );

      expect(out, {'mediaId': 'm1'});
    });

    test('putBytesJson rejects a non-2xx status with the API error', () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode({'error': 'too big'}), 413),
      );

      await expectLater(
        _client(mock).putBytesJson(
          '/audio/media/m1',
          bytes: const [1, 2, 3],
          contentType: 'audio/mpeg',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 413)
              .having((e) => e.body, 'body', {'error': 'too big'}),
        ),
      );
    });

    test('putBytesJson rejects a 2xx body that is not a JSON object', () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode([1, 2]), 200),
      );

      await expectLater(
        _client(mock).putBytesJson(
          '/audio/media/m1',
          bytes: const [1, 2, 3],
          contentType: 'audio/mpeg',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Expected JSON object',
          ),
        ),
      );
    });

    test('postMultipartJson decodes a 2xx JSON object body', () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode({'text': 'hello'}), 200),
      );

      final out = await _client(mock).postMultipartJson(
        '/transcriptions',
        fileFieldName: 'file',
        fileBytes: const [1, 2, 3],
      );

      expect(out, {'text': 'hello'});
    });

    test(
      'postMultipartJson rejects a non-2xx status with the API error',
      () async {
        final mock = MockClient(
          (_) async => http.Response(jsonEncode({'error': 'nope'}), 500),
        );

        await expectLater(
          _client(mock).postMultipartJson(
            '/transcriptions',
            fileFieldName: 'file',
            fileBytes: const [1, 2, 3],
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.body, 'body', {'error': 'nope'}),
          ),
        );
      },
    );

    test(
      'postMultipartJson rejects a 2xx body that is not a JSON object',
      () async {
        final mock = MockClient(
          (_) async => http.Response(jsonEncode('plain'), 200),
        );

        await expectLater(
          _client(mock).postMultipartJson(
            '/transcriptions',
            fileFieldName: 'file',
            fileBytes: const [1, 2, 3],
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Expected JSON object',
            ),
          ),
        );
      },
    );
  });

  group('ApiClient URL resolution is shared', () {
    test('putBytesJson strips the trailing slash from the base URL', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      });

      await _client(mock, baseUrl: 'https://api.example.com/').putBytesJson(
        '/audio/media/m1',
        bytes: const [1, 2, 3],
        contentType: 'audio/mpeg',
      );

      expect(captured!.url.path, '/audio/media/m1');
    });

    test(
      'postMultipartJson strips the trailing slash from the base URL',
      () async {
        http.Request? captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response('{}', 200);
        });

        await _client(
          mock,
          baseUrl: 'https://api.example.com/',
        ).postMultipartJson(
          '/transcriptions',
          fileFieldName: 'file',
          fileBytes: const [1, 2, 3],
        );

        expect(captured!.url.path, '/transcriptions');
      },
    );
  });
}
