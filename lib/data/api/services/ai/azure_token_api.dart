/// `POST /azure/tokens` — reserved for future TTS / assessment on-device Azure.
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

class AzureTokenApi extends RestApi {
  AzureTokenApi(super.client);

  static const _path = '/azure/tokens';

  Future<JsonMap> generateToken({JsonMap? usage}) {
    return client.postJson(
      _path,
      body: usage == null ? <String, dynamic>{} : {'usage': usage},
    );
  }
}
