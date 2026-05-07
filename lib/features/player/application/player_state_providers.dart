/// Raw [PlayerEngine] transport streams for UI (playing / buffering).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine_provider.dart';

final playerIsPlayingProvider = StreamProvider<bool>((ref) {
  return ref.watch(playerEngineProvider).playing;
});

final playerIsBufferingProvider = StreamProvider<bool>((ref) {
  return ref.watch(playerEngineProvider).buffering;
});
