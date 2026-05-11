/// `POST /azure/tokens` — reserved for future TTS / assessment on-device Azure.
library;

import 'package:enjoy_player/data/api/api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class AzureTokenApi {
  AzureTokenApi(this._client);

  final ApiClient _client;

  static const _path = '/azure/tokens';

  Future<JsonMap> generateToken({JsonMap? usage}) {
    return _client.postJson(
      _path,
      body: usage == null ? <String, dynamic>{} : {'usage': usage},
    );
  }
}
