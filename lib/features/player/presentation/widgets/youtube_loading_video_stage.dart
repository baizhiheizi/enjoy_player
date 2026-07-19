/// 16:9 portal target + poster while YouTube [openMedia] is in flight.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/application/youtube_open_preview_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_surface_target.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_poster.dart';

class YoutubeLoadingVideoStage extends ConsumerWidget {
  const YoutubeLoadingVideoStage({required this.mediaId, super.key});

  final String mediaId;

  static const double aspectWidth = 16;
  static const double aspectHeight = 9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(youtubeOpenPreviewProvider(mediaId));
    final engine = ref.watch(playerEngineProvider);
    final yt = engine is YoutubePlayerEngine ? engine : null;

    final thumb = preview.maybeWhen(
      data: (p) => p?.thumbnailUrl,
      orElse: () => null,
    );

    if (yt != null) {
      yt.setPosterUrl(thumb);
      yt.ensureWebViewAttached();
    }

    final showSurface = yt != null && yt.shouldMountWebView;

    return SafeArea(
      top: true,
      bottom: false,
      left: false,
      right: false,
      child: AspectRatio(
        aspectRatio: aspectWidth / aspectHeight,
        child: PlayerSurfaceTarget(
          id: PlayerSurfaceIds.expandedPlayerLoading,
          enabled: showSurface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              YoutubeVideoPoster(primaryUrl: thumb, visible: true),
            ],
          ),
        ),
      ),
    );
  }
}
