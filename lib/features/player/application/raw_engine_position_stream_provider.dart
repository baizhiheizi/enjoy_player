/// Single shared raw engine position stream so display/scrubber/tracker all
/// derive from one canonical source instead of subscribing independently.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine_provider.dart';

final rawEnginePositionStreamProvider = Provider<Stream<Duration>>((ref) {
  final engine = ref.watch(playerEngineProvider);
  return engine.position;
});
