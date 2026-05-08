/// `/api/v1/mine/recordings` (ported from `@enjoy/api` recording service).
library;

import 'package:enjoy_player/data/api/api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class RecordingApi {
  RecordingApi(this._client, {this.clientPlatform = 'flutter'});

  final ApiClient _client;

  /// Sent as `client_platform` (snake) on upload metadata.
  final String clientPlatform;

  static const _path = '/api/v1/mine/recordings';

  Future<List<JsonMap>> recordings({
    String? targetId,
    String? targetType,
    String? language,
    int? limit,
    String? updatedAfter,
  }) {
    final q = <String, String>{};
    if (targetId != null) q['targetId'] = targetId;
    if (targetType != null) q['targetType'] = targetType;
    if (language != null) q['language'] = language;
    if (limit != null) q['limit'] = '$limit';
    if (updatedAfter != null) q['updatedAfter'] = updatedAfter;
    return _client.getJsonList(
      _path,
      queryParameters: q.isEmpty ? null : q,
    );
  }

  Future<JsonMap> recording(String id) => _client.getJson('$_path/$id');

  Future<JsonMap> uploadRecording(JsonMap recording) {
    final payload = <String, dynamic>{
      if (recording['id'] != null) 'id': recording['id'],
      if (recording['targetId'] != null) 'targetId': recording['targetId'],
      if (recording['targetType'] != null) 'targetType': recording['targetType'],
      if (recording['duration'] != null) 'duration': recording['duration'],
      if (recording['md5'] != null) 'md5': recording['md5'],
      if (recording['referenceText'] != null) 'referenceText': recording['referenceText'],
      if (recording['referenceStart'] != null) 'referenceStart': recording['referenceStart'],
      if (recording['referenceDuration'] != null)
        'referenceDuration': recording['referenceDuration'],
      if (recording['language'] != null) 'language': recording['language'],
      'clientPlatform': clientPlatform,
      if (recording['createdAt'] != null) 'createdAt': recording['createdAt'],
      if (recording['updatedAt'] != null) 'updatedAt': recording['updatedAt'],
    };
    return _client.postJson(
      _path,
      body: {'recording': payload},
    );
  }

  Future<JsonMap> deleteRecording(String id) => _client.deleteJson('$_path/$id');

  Future<JsonMap> updateRecording(
    String id,
    JsonMap data, {
    bool skipTransform = false,
  }) =>
      _client.putJson(
        '$_path/$id',
        body: data,
        transformBody: !skipTransform,
      );
}
