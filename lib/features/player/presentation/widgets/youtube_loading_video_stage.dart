/// 16:9 portal target + poster while YouTube [openMedia] is in flight.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/player_engine_capabilities_provider.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/application/youtube_open_preview_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_loading_stage.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_poster.dart';

class YoutubeLoadingVideoStage extends ConsumerWidget {
  const YoutubeLoadingVideoStage({
    required this.mediaId,
    this.overlayBuilder,
    super.key,
  });

  final String mediaId;
  final PlayerSurfaceOverlayBuilder? overlayBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(youtubeOpenPreviewProvider(mediaId));
    // Capability via provider, not engine type tag (issue #720).
    final isYoutube = ref.watch(playerEnginePlaysYoutubeProvider);

    final thumb = preview.maybeWhen(
      data: (p) => p?.thumbnailUrl,
      orElse: () => null,
    );

    // Claim the loading portal whenever a YouTube engine is active — same
    // pattern as the local loading stage. WebView visibility is gated by
    // [YoutubePlayerEngine.shouldMountWebView] inside the surface host.
    final showSurface = isYoutube;

    return PlayerLoadingStage(
      surfaceId: PlayerSurfaceIds.expandedPlayerLoading,
      enabled: showSurface,
      overlayBuilder: overlayBuilder,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          YoutubeVideoPoster(primaryUrl: thumb, visible: true),
        ],
      ),
    );
  }
}
