import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/rest_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _SampleRestApi extends RestApi {
  _SampleRestApi(super.client);

  Future<List<JsonMap>> listItems([Map<String, Object?> params = const {}]) =>
      listResource('/api/v1/items', params);
}

ApiClient _client(MockClient mock) => ApiClient(
  httpClient: mock,
  getBaseUrl: () async => 'https://enjoy.example.com',
  getAccessToken: () async => 'tok',
);

void main() {
  group('RestApi.listResource', () {
    test('forwards query parameters through buildQuery', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('[{"id": "item-1"}]', 200);
      });

      final result = await _SampleRestApi(_client(mock)).listItems({
        'provider': 'youtube',
        'limit': 20,
        'empty': '',
        'absent': null,
      });

      expect(captured!.url.path, '/api/v1/items');
      expect(captured!.url.queryParameters, {
        'provider': 'youtube',
        'limit': '20',
      });
      expect(result, [
        {'id': 'item-1'},
      ]);
    });

    test('omits query parameters when map is empty', () async {
      http.Request? captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      });

      final result = await _SampleRestApi(_client(mock)).listItems();

      expect(captured!.url.path, '/api/v1/items');
      expect(captured!.url.queryParameters, isEmpty);
      expect(result, isEmpty);
    });
  });
}
