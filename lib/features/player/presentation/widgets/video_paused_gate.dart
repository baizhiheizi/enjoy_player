/// Fades overlay chrome out while playback runs (paused-title semantics):
/// nothing interactive sits over the video while it plays.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/player_state_providers.dart';

class VideoPausedGate extends ConsumerWidget {
  const VideoPausedGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerIsPlayingProvider).value ?? false;
    final isBuffering = ref.watch(playerIsBufferingProvider).value ?? false;
    final visible = !isPlaying || isBuffering;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }
}
