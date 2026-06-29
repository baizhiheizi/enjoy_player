/// Best-effort YouTube WebView pre-warm before navigating to the player.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/player_controller.dart';

void warmYoutubeSurfaceIfNeeded(WidgetRef ref, {required String? provider}) {
  if (provider?.toLowerCase() != 'youtube') return;
  ref.read(playerControllerProvider.notifier).warmYoutubeSurface();
}

void warmYoutubeSurfaceForVideoId(WidgetRef ref) {
  ref.read(playerControllerProvider.notifier).warmYoutubeSurface();
}
