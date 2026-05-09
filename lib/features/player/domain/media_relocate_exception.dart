/// Thrown when local media exists in the library but has no playable file on
/// this device (e.g. synced metadata from another client).
library;

import '../../library/domain/media.dart';

class MediaNeedsRelocateException implements Exception {
  const MediaNeedsRelocateException({
    required this.mediaId,
    required this.kind,
    required this.title,
    required this.expectedHash,
    this.expectedSize,
  });

  final String mediaId;
  final MediaKind kind;
  final String title;
  /// SHA-256 hex stored in Drift `md5` column.
  final String expectedHash;
  final int? expectedSize;

  @override
  String toString() =>
      'MediaNeedsRelocateException($mediaId, expectedHash=$expectedHash)';
}
