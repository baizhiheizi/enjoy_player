/// Quantized player position for transcript highlight + slider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'player_engine_provider.dart';
import 'position_buckets.dart';
import 'quantized_position.dart';

part 'display_position_provider.g.dart';

@riverpod
Stream<Duration> displayPosition(Ref ref) {
  final engine = ref.watch(playerEngineProvider);
  return quantizedPositionStream(
    engine.position,
    bucketMs: kPositionBucketDisplayMs,
  );
}
