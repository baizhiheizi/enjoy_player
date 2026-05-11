/// `POST /translations`.
library;

import 'package:enjoy_player/data/api/api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class TranslationApi {
  TranslationApi(this._client);

  final ApiClient _client;

  static const _path = '/translations';

  Future<JsonMap> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    return _client.postJson(
      _path,
      body: {
        'text': text,
        'sourceLang': sourceLanguage,
        'targetLang': targetLanguage,
        if (forceRefresh != null) 'forceRefresh': forceRefresh,
      },
    );
  }
}
