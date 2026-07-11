/// Finer-grained playback position for the transport scrubber (vs transcript bucket).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'position_buckets.dart';
import 'quantized_position.dart';
import 'raw_engine_position_stream_provider.dart';

final transportSliderPositionProvider = StreamProvider<Duration>((ref) {
  final rawStream = ref.watch(rawEnginePositionStreamProvider);
  return quantizedPositionStream(
    rawStream,
    bucketMs: kPositionBucketScrubberMs,
  );
});
