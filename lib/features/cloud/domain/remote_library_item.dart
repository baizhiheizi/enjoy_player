/// Remote-only row for the Cloud index (not persisted until user adds to library).
library;

class RemoteLibraryItem {
  const RemoteLibraryItem({
    required this.id,
    required this.isVideo,
    required this.title,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.language,
    this.mediaUrl,
    this.md5,
    this.size,
    required this.provider,
    required this.rawJson,
  });

  final String id;
  final bool isVideo;
  final String title;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String language;
  final String? mediaUrl;
  final String? md5;
  final int? size;
  /// Row `provider` after server-json normalization (e.g. `user`, `youtube`).
  final String provider;
  final Map<String, dynamic> rawJson;
}
