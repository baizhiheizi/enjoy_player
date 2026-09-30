/// Library read projection shared by the `videos` / `audios` DAOs.
///
/// Carries exactly the columns [MediaRegistry] maps onto the UI-facing
/// `Media` domain object — excluding fat row payload (`description`,
/// `bookmarkData` blobs, TTS metadata) that library listings never read
/// (issue #810 D6).
library;

class MediaLibraryRow {
  const MediaLibraryRow({
    required this.id,
    required this.title,
    required this.localUri,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.language,
    required this.contentHash,
    required this.size,
    required this.source,
    required this.provider,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? localUri;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String language;

  /// `videos.vid` / `audios.aid`.
  final String contentHash;
  final int? size;
  final String? source;
  final String provider;
  final String? syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaLibraryRow &&
        other.id == id &&
        other.title == title &&
        other.localUri == localUri &&
        other.mediaUrl == mediaUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.durationSeconds == durationSeconds &&
        other.language == language &&
        other.contentHash == contentHash &&
        other.size == size &&
        other.source == source &&
        other.provider == provider &&
        other.syncStatus == syncStatus &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    localUri,
    mediaUrl,
    thumbnailUrl,
    durationSeconds,
    language,
    contentHash,
    size,
    source,
    provider,
    syncStatus,
    createdAt,
    updatedAt,
  );
}
