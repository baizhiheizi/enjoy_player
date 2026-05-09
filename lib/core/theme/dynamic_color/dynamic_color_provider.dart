/// Riverpod providers exposing ArtworkPalette for the currently playing media.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/player_controller.dart';
import '../../utils/local_thumbnail.dart';
import 'artwork_palette.dart';

export 'artwork_palette.dart';

/// Artwork palette for the currently playing session.
/// Returns null when no media is playing or artwork extraction fails.
final currentArtworkPaletteProvider = FutureProvider<ArtworkPalette?>((ref) async {
  final thumbnailUrl = ref.watch(
    playerControllerProvider.select((s) => s?.thumbnailUrl),
  );
  final file = localThumbnailFile(thumbnailUrl);
  return extractArtworkPalette(file?.path);
});

/// Artwork palette for an arbitrary media item (used in library tiles).
final artworkPaletteProvider =
    FutureProvider.family<ArtworkPalette?, String?>((ref, thumbnailPath) async {
  return extractArtworkPalette(thumbnailPath);
});
