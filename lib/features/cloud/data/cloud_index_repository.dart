/// Fetches remote audio/video index pages (metadata only; no Drift writes).
library;

import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';

class CloudIndexRepository {
  CloudIndexRepository({
    required AudioApi audioApi,
    required VideoApi videoApi,
  })  : _audioApi = audioApi,
        _videoApi = videoApi;

  final AudioApi _audioApi;
  final VideoApi _videoApi;

  static const pageSize = 50;

  Future<List<RemoteLibraryItem>> fetchAudios({
    String? updatedAfter,
  }) async {
    final raw = await _audioApi.audios(
      limit: pageSize,
      updatedAfter: updatedAfter,
    );
    return raw.map(_audioToItem).toList();
  }

  Future<List<RemoteLibraryItem>> fetchVideos({
    String? updatedAfter,
  }) async {
    final raw = await _videoApi.videos(
      limit: pageSize,
      updatedAfter: updatedAfter,
    );
    return raw.map(_videoToItem).toList();
  }

  RemoteLibraryItem _audioToItem(Map<String, dynamic> m) {
    final row = audioRowFromServerJson(m);
    return RemoteLibraryItem(
      id: row.id,
      isVideo: false,
      title: row.title,
      thumbnailUrl: row.thumbnailUrl,
      durationSeconds: row.durationSeconds,
      language: row.language,
      mediaUrl: row.mediaUrl,
      md5: row.md5,
      size: row.size,
      rawJson: Map<String, dynamic>.from(m),
    );
  }

  RemoteLibraryItem _videoToItem(Map<String, dynamic> m) {
    final row = videoRowFromServerJson(m);
    return RemoteLibraryItem(
      id: row.id,
      isVideo: true,
      title: row.title,
      thumbnailUrl: row.thumbnailUrl,
      durationSeconds: row.durationSeconds,
      language: row.language,
      mediaUrl: row.mediaUrl,
      md5: row.md5,
      size: row.size,
      rawJson: Map<String, dynamic>.from(m),
    );
  }
}
