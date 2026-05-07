/// Throttled is optional; exposes player position for transcript highlight + slider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'player_controller.dart';

part 'display_position_provider.g.dart';

@riverpod
Stream<Duration> displayPosition(Ref ref) {
  final ctrl = ref.watch(playerControllerProvider.notifier);
  // Windows accessibility bridge can get flooded when semantics-heavy widgets
  // (slider, transcript list items) rebuild for every raw position tick.
  // Quantize updates to 200ms buckets to keep UI responsive without emitting
  // per-frame updates.
  const bucketMs = 200;
  return ctrl.player.stream.position
      .map((position) {
        final ms = position.inMilliseconds;
        final quantizedMs = (ms ~/ bucketMs) * bucketMs;
        return Duration(milliseconds: quantizedMs);
      })
      .distinct();
}
