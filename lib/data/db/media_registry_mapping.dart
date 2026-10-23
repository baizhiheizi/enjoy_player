part of 'media_registry.dart';

/// Maps a [VideoRow] to the UI-facing domain [Media].
Media mediaFromVideo(VideoRow row) => mediaFromLibraryRow(
  id: row.id,
  kind: MediaKind.video,
  title: row.title,
  localUri: row.localUri,
  mediaUrl: row.mediaUrl,
  thumbnailUrl: row.thumbnailUrl,
  durationSeconds: row.durationSeconds,
  language: row.language,
  contentHash: row.vid,
  size: row.size,
  source: row.source,
  provider: row.provider,
  syncStatus: row.syncStatus,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

/// Maps an [AudioRow] to the UI-facing domain [Media].
Media mediaFromAudio(AudioRow row) => mediaFromLibraryRow(
  id: row.id,
  kind: MediaKind.audio,
  title: row.title,
  localUri: row.localUri,
  mediaUrl: row.mediaUrl,
  thumbnailUrl: row.thumbnailUrl,
  durationSeconds: row.durationSeconds,
  language: row.language,
  contentHash: row.aid,
  size: row.size,
  source: row.source,
  provider: row.provider,
  syncStatus: row.syncStatus,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

Media mediaFromLibraryRow({
  required String id,
  required MediaKind kind,
  required String title,
  required String? localUri,
  required String? mediaUrl,
  required String? thumbnailUrl,
  required int durationSeconds,
  required String language,
  required String contentHash,
  required int? size,
  required String? source,
  required String provider,
  String? syncStatus,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return Media(
    id: id,
    kind: kind,
    title: title,
    sourceUri: localUri ?? mediaUrl ?? '',
    thumbnailPath: thumbnailUrl,
    durationMs: durationSeconds * 1000,
    language: language,
    contentHash: contentHash,
    fileSize: size ?? 0,
    mediaUrl: mediaUrl,
    source: source,
    provider: provider,
    syncStatus: syncStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Maps a [MediaLibraryRow] projection of either table onto [Media]
/// (issue #810 D6: DAO reads project only these columns).
Media mediaFromLibraryProjection(
  MediaLibraryRow row, {
  required MediaKind kind,
}) {
  return mediaFromLibraryRow(
    id: row.id,
    kind: kind,
    title: row.title,
    localUri: row.localUri,
    mediaUrl: row.mediaUrl,
    thumbnailUrl: row.thumbnailUrl,
    durationSeconds: row.durationSeconds,
    language: row.language,
    contentHash: row.contentHash,
    size: row.size,
    source: row.source,
    provider: row.provider,
    syncStatus: row.syncStatus,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
