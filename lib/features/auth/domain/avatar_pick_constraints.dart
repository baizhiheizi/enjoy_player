/// Client-side preflight for profile avatar picks (matches enjoy_web limits).
library;

/// Max avatar payload size accepted by `PATCH /api/v1/profile` (2 MiB).
const int kAvatarMaxBytes = 2 * 1024 * 1024;

/// MIME types accepted by enjoy_web `User::AVATAR_CONTENT_TYPES`.
const Set<String> kAvatarAllowedContentTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

/// File extensions accepted for avatar picks (lowercase, with leading dot).
const Set<String> kAvatarAllowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

enum AvatarPickFailure { empty, tooLarge, unsupportedType }

/// Validates [byteLength] and optional [filename] / [contentType] for avatar upload.
AvatarPickFailure? validateAvatarPick({
  required int byteLength,
  String? filename,
  String? contentType,
}) {
  if (byteLength <= 0) return AvatarPickFailure.empty;
  if (byteLength > kAvatarMaxBytes) return AvatarPickFailure.tooLarge;

  final mime = contentType?.trim().toLowerCase();
  if (mime != null && mime.isNotEmpty) {
    if (!kAvatarAllowedContentTypes.contains(mime)) {
      return AvatarPickFailure.unsupportedType;
    }
    return null;
  }

  final name = filename?.trim().toLowerCase() ?? '';
  final dot = name.lastIndexOf('.');
  if (dot < 0) return AvatarPickFailure.unsupportedType;
  final ext = name.substring(dot);
  if (!kAvatarAllowedExtensions.contains(ext)) {
    return AvatarPickFailure.unsupportedType;
  }
  return null;
}

/// Infers a content type from [filename] for direct-upload metadata.
String? avatarContentTypeForFilename(String filename) {
  final name = filename.trim().toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  return null;
}
