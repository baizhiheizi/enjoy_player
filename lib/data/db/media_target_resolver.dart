/// Resolve weapp-style `TargetType` from a library item id (video vs audio row).
library;

import 'dart:typed_data';

import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/files/local_uri_trust.dart';
import 'package:enjoy_player/data/files/security_scoped_bookmark.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';

import 'app_database.dart';
import 'media_registry.dart';

Future<String?> dexieTargetTypeForId(AppDatabase db, String id) =>
    MediaRegistry(db).dexieTargetTypeForId(id);

/// Same resolution as [PlayerController.openMedia] — returns structured source.
Future<PlayableSource?> resolvePlayableSource(
  AppDatabase db,
  String mediaId,
) async {
  final hit = await MediaRegistry(db).probeBoth(mediaId);
  final video = hit.video;
  final audio = hit.audio;
  if (video == null && audio == null) return null;

  if (video != null) {
    final ytId = youtubePlaybackVideoId(
      provider: video.provider,
      vid: video.vid,
      mediaUrl: video.mediaUrl,
      source: video.source,
    );
    if (ytId != null) {
      return YoutubePlayableSource(ytId);
    }
  }

  final local = video?.localUri ?? audio?.localUri;
  final bookmark = video?.bookmarkData ?? audio?.bookmarkData;

  if (bookmark != null && bookmark.isNotEmpty) {
    final source = await resolvePlayableSourceFromBookmark(
      bookmark: bookmark,
      fallbackLocalUri: local,
      storedSize: video?.size ?? audio?.size,
      storedMtimeMs: video?.localMtimeMs ?? audio?.localMtimeMs,
    );
    if (source != null) return source;
  }

  final trusted = await localUriTrusted(
    localUri: local,
    storedSize: video?.size ?? audio?.size,
    storedMtimeMs: video?.localMtimeMs ?? audio?.localMtimeMs,
  );
  if (trusted) {
    return LocalFilePlayableSource(local!);
  }
  final netUri = video?.mediaUrl ?? audio?.mediaUrl;
  if (netUri != null && netUri.isNotEmpty) {
    return RemoteUrlPlayableSource(netUri);
  }
  return null;
}

/// Same resolution as [PlayerController.openMedia] — for subtitle extraction, etc.
Future<String?> resolvePlayableSourceUri(AppDatabase db, String mediaId) async {
  final hit = await MediaRegistry(db).probeBoth(mediaId);
  final video = hit.video;
  final audio = hit.audio;
  if (video == null && audio == null) return null;

  if (video != null) {
    final ytId = youtubePlaybackVideoId(
      provider: video.provider,
      vid: video.vid,
      mediaUrl: video.mediaUrl,
      source: video.source,
    );
    if (ytId != null) {
      return null;
    }
  }

  final local = video?.localUri ?? audio?.localUri;
  final bookmark = video?.bookmarkData ?? audio?.bookmarkData;

  if (bookmark != null && bookmark.isNotEmpty) {
    final resolved = await SecurityScopedBookmarkChannel.resolveBookmark(
      bookmark,
    );
    if (resolved != null) {
      await SecurityScopedBookmarkChannel.releaseBookmark(resolved.token);
      return resolved.path;
    }
  }

  final trusted = await localUriTrusted(
    localUri: local,
    storedSize: video?.size ?? audio?.size,
    storedMtimeMs: video?.localMtimeMs ?? audio?.localMtimeMs,
  );
  if (trusted) {
    return local;
  }
  final netUri = video?.mediaUrl ?? audio?.mediaUrl;
  if (netUri != null && netUri.isNotEmpty) {
    return netUri;
  }
  return null;
}

/// Resolves [bookmark] and starts the security-scoped access grant. When
/// resolution succeeds, returns a [LocalFilePlayableSource] whose
/// [LocalFilePlayableSource.scopeToken] must be released by the engine
/// before the next `open()` or on `dispose()`. When resolution fails,
/// returns `null` so the caller can fall back to the legacy [localUri]
/// path (or ultimately surface a `MediaNeedsRelocateException`).
Future<LocalFilePlayableSource?> resolvePlayableSourceFromBookmark({
  required Uint8List bookmark,
  required String? fallbackLocalUri,
  required int? storedSize,
  required int? storedMtimeMs,
}) async {
  final resolved = await SecurityScopedBookmarkChannel.resolveBookmark(
    bookmark,
  );
  if (resolved == null) return null;
  final trusted = await localUriTrusted(
    localUri: resolved.path,
    storedSize: storedSize,
    storedMtimeMs: storedMtimeMs,
  );
  if (!trusted) {
    await SecurityScopedBookmarkChannel.releaseBookmark(resolved.token);
    return null;
  }
  return LocalFilePlayableSource(resolved.path, scopeToken: resolved.token);
}
