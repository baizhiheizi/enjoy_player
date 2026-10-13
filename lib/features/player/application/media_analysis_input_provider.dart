/// Input FFmpeg can decode for a media item: its local file, or its remote
/// HTTP(S) URL when no local copy exists.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';

/// Local file path of [mediaId] when the row has a local copy; otherwise its
/// `http(s)` media URL (cloud-streamed library items). `null` for YouTube
/// rows (no direct audio URL) and rows with neither.
///
/// Reads `localUri` directly rather than through `resolvePlayableSource`, so
/// no macOS security-scoped bookmark grant is opened for an analysis read.
Future<String?> resolveMediaAnalysisInput(
  MediaRegistry mediaRegistry,
  String mediaId,
) async {
  final hit = await mediaRegistry.probeBoth(mediaId);
  final video = hit.video;
  final audio = hit.audio;
  if (video == null && audio == null) return null;

  final local = video?.localUri ?? audio?.localUri;
  if (local != null && local.isNotEmpty) {
    try {
      return Uri.parse(local).toFilePath();
    } catch (_) {
      return local;
    }
  }

  if (video != null &&
      youtubePlaybackVideoId(
            provider: video.provider,
            vid: video.vid,
            mediaUrl: video.mediaUrl,
            source: video.source,
          ) !=
          null) {
    return null;
  }
  final remote = (video?.mediaUrl ?? audio?.mediaUrl)?.trim();
  if (remote == null) return null;
  final scheme = Uri.tryParse(remote)?.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https' ? remote : null;
}

/// Analysis input of [mediaId] (see [resolveMediaAnalysisInput]) — gates the
/// embeds that decode the media's audio (pitch contour analysis).
///
/// Auto-dispose on the same rationale as `localThumbnailFileProvider`: a
/// relink can land after a mount that found none, so a negative answer must
/// not outlive the screen that asked for it. Keyed on media id, so embeds
/// reset on media change for free.
final mediaAnalysisInputProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, mediaId) {
      return resolveMediaAnalysisInput(
        ref.watch(mediaRegistryProvider),
        mediaId,
      );
    });
