/// Finer-grained playback position for the transport scrubber (vs transcript bucket).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine_provider.dart';

/// ~50ms buckets — smooth enough for the slider without flooding semantics rebuilds.
final transportSliderPositionProvider = StreamProvider<Duration>((ref) {
  final engine = ref.watch(playerEngineProvider);
  const bucketMs = 50;
  return engine.position
      .map((position) {
        final ms = position.inMilliseconds;
        final quantizedMs = (ms ~/ bucketMs) * bucketMs;
        return Duration(milliseconds: quantizedMs);
      })
      .distinct();
});
