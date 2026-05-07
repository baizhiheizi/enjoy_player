/// Declarative open for a route param [mediaId] (race-safe inside [PlayerController]).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_controller.dart';

final openMediaActionProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  mediaId,
) async {
  await ref.read(playerControllerProvider.notifier).openMedia(mediaId);
});
