/// Injectable [PlayerEngine] (override in tests with a fake).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine.dart';

final playerEngineProvider = Provider<PlayerEngine>((ref) {
  final engine = MediaKitPlayerEngine();
  ref.onDispose(engine.dispose);
  return engine;
});
