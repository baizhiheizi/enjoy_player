/// `POST /dictionary/query`.
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

class DictionaryApi extends RestApi {
  DictionaryApi(super.client);

  static const _path = '/dictionary/query';

  Future<JsonMap> query({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    return client.postJson(
      _path,
      body: {
        'word': word,
        'sourceLang': sourceLanguage,
        'targetLang': targetLanguage,
        'forceRefresh': ?forceRefresh,
      },
    );
  }
}
