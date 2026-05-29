/// Card artwork URLs — upgrades letterboxed YouTube thumbs to 16:9 variants.
library;

import 'dart:io' show File;

import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/features/library/domain/media.dart';

import 'local_thumbnail.dart';

final RegExp _ytimgVideoId = RegExp(r'i\.ytimg\.com/vi/([a-zA-Z0-9_-]{11})');

bool isRemoteThumbnailUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final u = Uri.tryParse(url);
  return u != null &&
      u.hasScheme &&
      (u.isScheme('http') || u.isScheme('https'));
}

/// Extracts a YouTube video id from an `i.ytimg.com/vi/…` artwork URL.
String? youtubeVideoIdFromThumbnailUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final match = _ytimgVideoId.firstMatch(url);
  return match?.group(1);
}

/// Preferred 16:9 card artwork (`maxresdefault`, 1280×720 when available).
String youtubeMaxResThumbnailUrl(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';

/// Reliable 16:9 fallback (`mqdefault`, 320×180).
String youtubeMqThumbnailUrl(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

String? _resolveYoutubeVideoId({
  String? youtubeVideoId,
  String? thumbnailPath,
  String? mediaUrl,
}) {
  final fromArg = parseYoutubeVideoId(youtubeVideoId ?? '');
  if (fromArg != null) return fromArg;
  final fromThumb = youtubeVideoIdFromThumbnailUrl(thumbnailPath);
  if (fromThumb != null) return fromThumb;
  return parseYoutubeVideoId(mediaUrl ?? '');
}

/// When set, library/home cards should use [Image.network] instead of a local file.
///
/// YouTube `hqdefault` URLs (oEmbed) are 4:3 with baked-in letterboxing — cards
/// upgrade to 16:9 `maxresdefault` (see [_YoutubeCoverImage] fallback).
String? remoteThumbnailForCard(
  String? thumbnailPath, {
  String? youtubeVideoId,
  String? mediaUrl,
}) {
  final videoId = _resolveYoutubeVideoId(
    youtubeVideoId: youtubeVideoId,
    thumbnailPath: thumbnailPath,
    mediaUrl: mediaUrl,
  );
  if (videoId != null) {
    return youtubeMaxResThumbnailUrl(videoId);
  }
  return isRemoteThumbnailUrl(thumbnailPath) ? thumbnailPath : null;
}

/// MQ fallback when [remoteThumbnailForCard] returns maxres for YouTube.
String? youtubeMqFallbackForCardUrl(String? primaryUrl) {
  final videoId = youtubeVideoIdFromThumbnailUrl(primaryUrl);
  if (videoId == null) return null;
  return youtubeMqThumbnailUrl(videoId);
}

/// Local file artwork for cards when [thumbnailPath] is not an `http(s)` URL.
File? localThumbnailFileForCard(String? thumbnailPath) {
  if (isRemoteThumbnailUrl(thumbnailPath)) return null;
  return localThumbnailFile(thumbnailPath);
}

/// Network artwork for a library [Media] row (YouTube prefers 16:9 CDN URLs).
String? networkThumbnailForMedia(Media media) {
  return remoteThumbnailForCard(
    media.thumbnailPath,
    youtubeVideoId: media.provider == 'youtube' ? media.contentHash : null,
    mediaUrl: media.mediaUrl,
  );
}

/// Local artwork file when not superseded by a better remote YouTube URL.
File? localThumbnailFileForMedia(Media media) {
  if (media.provider == 'youtube' && networkThumbnailForMedia(media) != null) {
    return null;
  }
  return localThumbnailFileForCard(media.thumbnailPath);
}
