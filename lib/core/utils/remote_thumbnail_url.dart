/// Whether [url] is an http(s) artwork URL suitable for API sync payloads.
library;

import 'dart:io' show File;

import 'local_thumbnail.dart';

bool isRemoteThumbnailUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final u = Uri.tryParse(url);
  return u != null &&
      u.hasScheme &&
      (u.isScheme('http') || u.isScheme('https'));
}

/// When set, library/home cards should use [Image.network] instead of a local file.
String? remoteThumbnailForCard(String? thumbnailPath) {
  return isRemoteThumbnailUrl(thumbnailPath) ? thumbnailPath : null;
}

/// Local file artwork for cards when [thumbnailPath] is not an `http(s)` URL.
File? localThumbnailFileForCard(String? thumbnailPath) {
  if (isRemoteThumbnailUrl(thumbnailPath)) return null;
  return localThumbnailFile(thumbnailPath);
}
