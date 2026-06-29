/// Finer-grained playback position for the transport scrubber (vs transcript bucket).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine_provider.dart';
import 'position_buckets.dart';
import 'quantized_position.dart';

final transportSliderPositionProvider = StreamProvider<Duration>((ref) {
  final engine = ref.watch(playerEngineProvider);
  return quantizedPositionStream(
    engine.position,
    bucketMs: kPositionBucketScrubberMs,
  );
});
