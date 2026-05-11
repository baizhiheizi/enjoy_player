/// Thumbnail tile for mini transport (art only — no second [Video]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TransportArtworkTile extends ConsumerWidget {
  const TransportArtworkTile({super.key, required this.chrome});

  final PlaybackChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isVideo = chrome.mediaType == 'video';
    const width = 64.0;
    const height = 40.0;

    // ADR-0003: single media_kit Player/VideoController — do not attach a second
    // [Video] here; the expanded player owns the texture. Mini bar uses art only.
    final thumb = localThumbnailFile(chrome.thumbnailUrl);
    final Widget content =
        thumb != null
            ? Image.file(
              thumb,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => transportArtworkFallback(cs, isVideo: isVideo),
            )
            : transportArtworkFallback(cs, isVideo: isVideo);

    return Semantics(
      label: isVideo ? l10n.miniPlayerMediaVideo : l10n.miniPlayerMediaAudio,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: InkWell(
            onTap: () => openPlayerRoute(context, chrome.mediaId),
            child: content,
          ),
        ),
      ),
    );
  }
}

Widget transportArtworkFallback(ColorScheme cs, {required bool isVideo}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cs.surfaceContainerHighest, cs.surfaceContainer],
      ),
    ),
    child: Center(
      child: Icon(
        isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
        size: 22,
        color: cs.onSurfaceVariant,
      ),
    ),
  );
}
