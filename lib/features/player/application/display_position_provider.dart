/// Quantized player position for transcript highlight + slider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'player_engine_provider.dart';
import 'quantized_position.dart';

part 'display_position_provider.g.dart';

@riverpod
Stream<Duration> displayPosition(Ref ref) {
  final engine = ref.watch(playerEngineProvider);
  // Windows accessibility bridge can get flooded when semantics-heavy widgets
  // (slider, transcript list items) rebuild for every raw position tick.
  return quantizedPositionStream(engine.position, bucketMs: 400);
}
