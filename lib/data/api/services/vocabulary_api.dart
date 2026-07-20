/// `/api/v1/mine/vocabulary_items` and `/vocabulary_contexts` (ported from
/// `@enjoy/api` vocabulary service). See ADR-0054.
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/query_params.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

class VocabularyApi extends RestApi {
  VocabularyApi(super.client);

  static const _itemsPath = '/api/v1/mine/vocabulary_items';
  static const _contextsPath = '/api/v1/mine/vocabulary_contexts';

  Future<List<JsonMap>> vocabularyItems({int? limit, String? updatedAfter}) {
    return client.getJsonList(
      _itemsPath,
      queryParameters: buildQuery({
        'limit': limit,
        'updatedAfter': updatedAfter,
      }),
    );
  }

  Future<JsonMap> vocabularyItem(String id) =>
      client.getJson('$_itemsPath/$id');

  Future<JsonMap> uploadVocabularyItem(JsonMap vocabularyItem) =>
      client.postJson(_itemsPath, body: {'vocabularyItem': vocabularyItem});

  Future<JsonMap> deleteVocabularyItem(String id) =>
      client.deleteJson('$_itemsPath/$id');

  Future<List<JsonMap>> vocabularyContexts({
    String? vocabularyItemId,
    int? limit,
    String? updatedAfter,
  }) {
    return client.getJsonList(
      _contextsPath,
      queryParameters: buildQuery({
        'vocabularyItemId': vocabularyItemId,
        'limit': limit,
        'updatedAfter': updatedAfter,
      }),
    );
  }

  Future<JsonMap> vocabularyContext(String id) =>
      client.getJson('$_contextsPath/$id');

  Future<JsonMap> uploadVocabularyContext(JsonMap vocabularyContext) => client
      .postJson(_contextsPath, body: {'vocabularyContext': vocabularyContext});

  Future<JsonMap> deleteVocabularyContext(String id) =>
      client.deleteJson('$_contextsPath/$id');
}
