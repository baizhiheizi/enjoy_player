/// Video endpoints (ported from `@enjoy/api` video service).
library;

import 'package:enjoy_player/data/api/api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class VideoApi {
  VideoApi(this._client);

  final ApiClient _client;

  static const _minePath = '/api/v1/mine/videos';
  static const _publicPath = '/api/v1/videos';

  Future<List<JsonMap>> videos({
    String? provider,
    int? limit,
    String? updatedAfter,
  }) {
    final q = <String, String>{};
    if (provider != null) q['provider'] = provider;
    if (limit != null) q['limit'] = '$limit';
    if (updatedAfter != null) q['updatedAfter'] = updatedAfter;
    return _client.getJsonList(
      _minePath,
      queryParameters: q.isEmpty ? null : q,
    );
  }

  Future<JsonMap> video(String id) => _client.getJson('$_minePath/$id');

  Future<JsonMap> uploadVideo(JsonMap video) => _client.postJson(
        _minePath,
        body: {'video': video},
      );

  Future<JsonMap> deleteVideo(String id) => _client.deleteJson('$_minePath/$id');

  Future<JsonMap> registerVideo(JsonMap data) => _client.postJson(
        _publicPath,
        body: data,
      );

  Future<({List<JsonMap> videos, JsonMap pagy})> listVideos({
    String? provider,
    int? page,
    int? limit,
    String? updatedAfter,
  }) async {
    final q = <String, String>{};
    if (provider != null) q['provider'] = provider;
    if (page != null) q['page'] = '$page';
    if (limit != null) q['limit'] = '$limit';
    if (updatedAfter != null) q['updatedAfter'] = updatedAfter;
    final m = await _client.getJson(
      _publicPath,
      queryParameters: q.isEmpty ? null : q,
    );
    final rawVideos = m['videos'];
    final rawPagy = m['pagy'];
    if (rawVideos is! List) {
      throw StateError('listVideos: expected videos list');
    }
    final videos = rawVideos.map<JsonMap>((e) {
      if (e is JsonMap) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      throw StateError('listVideos: invalid video entry');
    }).toList();
    final pagy = rawPagy is JsonMap
        ? rawPagy
        : (rawPagy is Map
              ? Map<String, dynamic>.from(rawPagy)
              : <String, dynamic>{});
    return (videos: videos, pagy: pagy);
  }
}
