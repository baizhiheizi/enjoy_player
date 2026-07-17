import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';

Map<String, dynamic> _decode(String body) =>
    Map<String, dynamic>.from(jsonDecode(body) as Map);

void main() {
  test('vocabularyItems builds query and parses list envelope', () async {
    http.Request? captured;
    final mock = MockClient((request) async {
      captured = request;
      return http.Response(
        '[{"id": "item-1", "word": "hello"}]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = VocabularyApi(
      ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://enjoy.example.com',
        getAccessToken: () async => 'tok',
      ),
    );

    final items = await api.vocabularyItems(
      limit: 50,
      updatedAfter: '2026-01-01T00:00:00.000Z',
    );

    expect(captured, isNotNull);
    final uri = captured!.url;
    expect(uri.path, '/api/v1/mine/vocabulary_items');
    expect(uri.queryParameters['limit'], '50');
    expect(uri.queryParameters['updated_after'], '2026-01-01T00:00:00.000Z');
    expect(items, hasLength(1));
    expect(items.single['word'], 'hello');
  });

  test('vocabularyItem fetches by id', () async {
    http.Request? captured;
    final mock = MockClient((request) async {
      captured = request;
      return http.Response(
        '{"id": "item-1", "word": "hello"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = VocabularyApi(
      ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://enjoy.example.com',
        getAccessToken: () async => 'tok',
      ),
    );

    final item = await api.vocabularyItem('item-1');

    expect(captured!.url.path, '/api/v1/mine/vocabulary_items/item-1');
    expect(item['id'], 'item-1');
  });

  test(
    'uploadVocabularyItem wraps the payload under vocabulary_item key',
    () async {
      Map<String, dynamic>? sentBody;
      final mock = MockClient((request) async {
        sentBody = _decode(request.body);
        return http.Response(
          '{"vocabularyItem": {"id": "item-1", "updatedAt": "2026-01-01T00:00:00.000Z"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = VocabularyApi(
        ApiClient(
          httpClient: mock,
          getBaseUrl: () async => 'https://enjoy.example.com',
          getAccessToken: () async => 'tok',
        ),
      );

      final response = await api.uploadVocabularyItem({
        'id': 'item-1',
        'word': 'hello',
      });

      expect(sentBody, isNotNull);
      expect(sentBody!.containsKey('vocabulary_item'), isTrue);
      expect(response['vocabularyItem'], isA<Map>());
    },
  );

  test('deleteVocabularyItem issues a DELETE to the item path', () async {
    http.Request? captured;
    final mock = MockClient((request) async {
      captured = request;
      return http.Response('', 200);
    });
    final api = VocabularyApi(
      ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://enjoy.example.com',
        getAccessToken: () async => 'tok',
      ),
    );

    await api.deleteVocabularyItem('item-1');

    expect(captured!.method, 'DELETE');
    expect(captured!.url.path, '/api/v1/mine/vocabulary_items/item-1');
  });

  test(
    'vocabularyContexts builds query with vocabularyItemId filter',
    () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = VocabularyApi(
        ApiClient(
          httpClient: mock,
          getBaseUrl: () async => 'https://enjoy.example.com',
          getAccessToken: () async => 'tok',
        ),
      );

      await api.vocabularyContexts(vocabularyItemId: 'item-1', limit: 10);

      expect(captured!.url.path, '/api/v1/mine/vocabulary_contexts');
      expect(captured!.url.queryParameters['vocabulary_item_id'], 'item-1');
      expect(captured!.url.queryParameters['limit'], '10');
    },
  );

  test(
    'uploadVocabularyContext wraps the payload under vocabulary_context key',
    () async {
      Map<String, dynamic>? sentBody;
      final mock = MockClient((request) async {
        sentBody = _decode(request.body);
        return http.Response(
          '{"vocabularyContext": {"id": "ctx-1", "updatedAt": "2026-01-01T00:00:00.000Z"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = VocabularyApi(
        ApiClient(
          httpClient: mock,
          getBaseUrl: () async => 'https://enjoy.example.com',
          getAccessToken: () async => 'tok',
        ),
      );

      final response = await api.uploadVocabularyContext({
        'id': 'ctx-1',
        'text': 'hello world',
      });

      expect(sentBody, isNotNull);
      expect(sentBody!.containsKey('vocabulary_context'), isTrue);
      expect(response['vocabularyContext'], isA<Map>());
    },
  );

  test('deleteVocabularyContext issues a DELETE to the context path', () async {
    http.Request? captured;
    final mock = MockClient((request) async {
      captured = request;
      return http.Response('', 200);
    });
    final api = VocabularyApi(
      ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://enjoy.example.com',
        getAccessToken: () async => 'tok',
      ),
    );

    await api.deleteVocabularyContext('ctx-1');

    expect(captured!.method, 'DELETE');
    expect(captured!.url.path, '/api/v1/mine/vocabulary_contexts/ctx-1');
  });
}
