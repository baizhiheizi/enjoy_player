/// Resolve weapp-style `TargetType` from a library item id (video vs audio row).
library;

import 'dart:io';

import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';

import 'app_database.dart';

Future<String?> dexieTargetTypeForId(AppDatabase db, String id) async {
  if (await db.videoDao.getById(id) != null) return 'Video';
  if (await db.audioDao.getById(id) != null) return 'Audio';
  return null;
}

Future<bool> _localUriPlayable(String? uri) async {
  if (uri == null || uri.isEmpty) return false;
  try {
    return File.fromUri(Uri.parse(uri)).exists();
  } on Object {
    return false;
  }
}

/// Same resolution as [PlayerController.openMedia] — returns structured source.
Future<PlayableSource?> resolvePlayableSource(
  AppDatabase db,
  String mediaId,
) async {
  final video = await db.videoDao.getById(mediaId);
  final audio = video == null ? await db.audioDao.getById(mediaId) : null;
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

  final netUri = video?.mediaUrl ?? audio?.mediaUrl;
  if (netUri != null && netUri.isNotEmpty) {
    return RemoteUrlPlayableSource(netUri);
  }
  final local = video?.localUri ?? audio?.localUri;
  if (await _localUriPlayable(local)) {
    return LocalFilePlayableSource(local!);
  }
  return null;
}

/// Same resolution as [PlayerController.openMedia] — for subtitle extraction, etc.
Future<String?> resolvePlayableSourceUri(AppDatabase db, String mediaId) async {
  final video = await db.videoDao.getById(mediaId);
  final audio = video == null ? await db.audioDao.getById(mediaId) : null;
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

  final netUri = video?.mediaUrl ?? audio?.mediaUrl;
  if (netUri != null && netUri.isNotEmpty) {
    return netUri;
  }
  final local = video?.localUri ?? audio?.localUri;
  if (await _localUriPlayable(local)) {
    return local;
  }
  return null;
}
