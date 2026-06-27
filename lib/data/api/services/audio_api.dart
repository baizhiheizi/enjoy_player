/// `/api/v1/mine/audios` (ported from `@enjoy/api` audio service).
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/query_params.dart';

typedef JsonMap = Map<String, dynamic>;

class AudioApi {
  AudioApi(this._client);

  final ApiClient _client;

  static const _path = '/api/v1/mine/audios';

  Future<List<JsonMap>> audios({
    String? provider,
    int? limit,
    String? updatedAfter,
  }) {
    return _client.getJsonList(
      _path,
      queryParameters: buildQuery({
        'provider': provider,
        'limit': limit,
        'updatedAfter': updatedAfter,
      }),
    );
  }

  Future<JsonMap> audio(String id) => _client.getJson('$_path/$id');

  Future<JsonMap> uploadAudio(JsonMap audio) =>
      _client.postJson(_path, body: {'audio': audio});

  Future<JsonMap> deleteAudio(String id) => _client.deleteJson('$_path/$id');
}
