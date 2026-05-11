/// `POST /dictionary/query`.
library;

import 'package:enjoy_player/data/api/api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class DictionaryApi {
  DictionaryApi(this._client);

  final ApiClient _client;

  static const _path = '/dictionary/query';

  Future<JsonMap> query({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    return _client.postJson(
      _path,
      body: {
        'word': word,
        'sourceLang': sourceLanguage,
        'targetLang': targetLanguage,
        if (forceRefresh != null) 'forceRefresh': forceRefresh,
      },
    );
  }
}
