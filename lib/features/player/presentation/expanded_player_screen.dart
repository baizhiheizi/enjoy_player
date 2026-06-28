/// Full-screen player: ambient artwork backdrop + transparent AppBar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/dynamic_color/dynamic_color_provider.dart';
import 'package:enjoy_player/features/player/application/open_media_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/application/player_ui_provider.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';

import 'expanded_player_widgets.dart';
import 'locate_media_screen.dart';

class ExpandedPlayerScreen extends ConsumerStatefulWidget {
  const ExpandedPlayerScreen({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<ExpandedPlayerScreen> createState() =>
      _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends ConsumerState<ExpandedPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerUiProvider.notifier).expand();
    });
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(openMediaActionProvider(widget.mediaId));
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final isPlaying = ref.watch(playerIsPlayingProvider).value ?? false;
    final paletteAsync = ref.watch(currentArtworkPaletteProvider);
    final accent = paletteAsync.value?.dominant;
    final cs = Theme.of(context).colorScheme;

    if (chrome != null && chrome.mediaId == widget.mediaId) {
      return ExpandedPlayerChromeBody(
        mediaId: widget.mediaId,
        chrome: chrome,
        isPlaying: isPlaying,
        accent: accent,
      );
    }

    if (open.hasError) {
      final err = open.error;
      if (err is MediaNeedsRelocateException) {
        return LocateMediaScreen(info: err);
      }
      return ExpandedPlayerGenericErrorBody(colorScheme: cs);
    }

    return ExpandedPlayerLoadingBody(colorScheme: cs, mediaId: widget.mediaId);
  }
}
