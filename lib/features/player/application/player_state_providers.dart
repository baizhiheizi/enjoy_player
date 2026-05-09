/// Raw [PlayerEngine] transport streams for UI (playing / buffering).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine_provider.dart';

Stream<T> _seedThenFollow<T>(T seed, Stream<T> rest) async* {
  yield seed;
  yield* rest;
}

final playerIsPlayingProvider = StreamProvider<bool>((ref) {
  final engine = ref.watch(playerEngineProvider);
  return _seedThenFollow(engine.player.state.playing, engine.playing).distinct();
});

final playerIsBufferingProvider = StreamProvider<bool>((ref) {
  final engine = ref.watch(playerEngineProvider);
  return _seedThenFollow(
    engine.player.state.buffering,
    engine.buffering,
  ).distinct();
});
