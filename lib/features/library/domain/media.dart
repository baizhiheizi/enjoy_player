/// UI-facing media item (decoupled from persistence rows).
library;

enum MediaKind { audio, video }

extension MediaKindX on MediaKind {
  String get storageValue => switch (this) {
    MediaKind.audio => 'audio',
    MediaKind.video => 'video',
  };

  static MediaKind fromStorage(String kind) {
    switch (kind) {
      case 'video':
        return MediaKind.video;
      default:
        return MediaKind.audio;
    }
  }
}

class Media {
  const Media({
    required this.id,
    required this.kind,
    required this.title,
    required this.sourceUri,
    this.thumbnailPath,
    required this.durationMs,
    required this.language,
    required this.fileHash,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final MediaKind kind;
  final String title;
  final String sourceUri;
  final String? thumbnailPath;
  final int durationMs;
  final String language;
  final String fileHash;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
}
