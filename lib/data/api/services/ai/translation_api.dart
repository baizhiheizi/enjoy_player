/// `POST /translations`.
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

class TranslationApi extends RestApi {
  TranslationApi(super.client);

  static const _path = '/translations';

  Future<JsonMap> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    return client.postJson(
      _path,
      body: {
        'text': text,
        'sourceLang': sourceLanguage,
        'targetLang': targetLanguage,
        'forceRefresh': ?forceRefresh,
      },
    );
  }
}
