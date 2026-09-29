/// Collapse expanded player chrome and pop the player route.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'
    show ProviderListenable;

import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/player/application/leave_player_session.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';

Future<void> collapseExpandedPlayer(WidgetRef ref, BuildContext context) =>
    collapseExpandedPlayerWith(ref.read, context);

/// Reader-based variant of [collapseExpandedPlayer] for callers outside the
/// widget tree (the hotkey command interface): [read] is a `ref.read` /
/// `ProviderContainer.read` tear-off.
Future<void> collapseExpandedPlayerWith(
  T Function<T>(ProviderListenable<T> provider) read,
  BuildContext context,
) async {
  final router = GoRouter.of(context);
  if (router.state.uri.path.startsWith('/player/')) {
    router.pop();
  }
  await read(windowFullscreenProvider.notifier).setFullscreen(false);
  if (read(playerControllerProvider) == null) {
    read(playerControllerProvider.notifier).abandonPendingOpen();
  } else {
    await clearLivePlaybackSessionWith(read);
  }
}
