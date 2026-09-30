/// On-disk path of a media item's local copy, keyed by media id.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';

/// Resolves [mediaRegistry]'s `localUri` for [mediaId] to a filesystem path,
/// falling back to the raw uri when it does not parse as a file URI.
Future<String?> resolveLocalMediaPath(
  MediaRegistry mediaRegistry,
  String mediaId,
) async {
  final uri = await mediaRegistry.localUriOf(mediaId);
  if (uri == null || uri.isEmpty) return null;
  try {
    return Uri.parse(uri).toFilePath();
  } catch (_) {
    return uri;
  }
}

/// Local file path of [mediaId], or `null` when the row is remote-only or
/// missing — gates embeds that read the audio file (pitch contour analysis).
///
/// Auto-dispose on the same rationale as `localThumbnailFileProvider`: a
/// relink can land after a mount that found none, so a negative answer must
/// not outlive the screen that asked for it. Keyed on media id, so embeds
/// reset on media change for free.
final localMediaPathProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, mediaId) {
      return resolveLocalMediaPath(ref.watch(mediaRegistryProvider), mediaId);
    });
