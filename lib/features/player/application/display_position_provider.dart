/// Quantized player position for transcript highlight + slider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'position_buckets.dart';
import 'quantized_position.dart';
import 'raw_engine_position_stream_provider.dart';

part 'display_position_provider.g.dart';

@riverpod
Stream<Duration> displayPosition(Ref ref) {
  final rawStream = ref.watch(rawEnginePositionStreamProvider);
  return quantizedPositionStream(rawStream, bucketMs: kPositionBucketDisplayMs);
}
