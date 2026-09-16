/// Presentation-facing capabilities of the active [PlayerEngine] (issue #720).
///
/// Widgets read these providers instead of branching on engine type tags or
/// reading capability members off the engine directly — the same
/// engine-kind-erasure rule as the application layer, expressed as Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';

/// Whether the active engine plays YouTube sources through the WebView
/// (ADR-0015). Replaces the old `engine.supportsYouTubePlayback` reads in
/// presentation (issue #720).
final playerEnginePlaysYoutubeProvider = Provider<bool>((ref) {
  final engine = ref.watch(playerEngineProvider);
  return engine is YoutubePlaybackEngine;
});

/// Whether the expanded player should show YouTube account chrome (WebView engine).
final playerYoutubeLoginChromeSupportedProvider = Provider<bool>((ref) {
  return ref.watch(playerEnginePlaysYoutubeProvider);
});
