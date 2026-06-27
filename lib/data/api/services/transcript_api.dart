/// `/api/v1/transcripts` (ported from `@enjoy/api` transcript service).
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/query_params.dart';

typedef JsonMap = Map<String, dynamic>;

class TranscriptApi {
  TranscriptApi(this._client);

  final ApiClient _client;

  static const _path = '/api/v1/transcripts';

  Future<List<JsonMap>> transcripts({
    String? targetId,
    String? targetType,
    String? source,
    String? language,
  }) {
    return _client.getJsonList(
      _path,
      queryParameters: buildQuery({
        'targetId': targetId,
        'targetType': targetType,
        'source': source,
        'language': language,
      }),
    );
  }

  Future<JsonMap> transcript(String id) => _client.getJson('$_path/$id');

  Future<JsonMap> uploadTranscript(JsonMap transcript) =>
      _client.postJson(_path, body: {'transcript': transcript});

  Future<JsonMap> syncTranscript(JsonMap data) =>
      _client.postJson(_path, body: data);
}
