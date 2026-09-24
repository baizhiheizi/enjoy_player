/// Active [PlayerEngine] — swapped when opening YouTube vs local/URL media (ADR-0015).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_controller.dart';
import 'player_engine.dart';
import 'player_engine_rev.dart';
import 'player_engine_test_double_provider.dart';

final playerEngineProvider = Provider<PlayerEngine>((ref) {
  // Do not watch [playerControllerProvider] (the session). Publishing the
  // session mounts transport chrome in the same frame; if this provider
  // also rebuilds then, [TransportProgressStrip] / transcript highlight
  // invalidate during build (UncontrolledProviderScope setState). Engine
  // identity is signaled by [playerEngineRevProvider] — the identity
  // module's internal change signal (issue #751) — and resolution itself
  // goes through [PlayerController.activeEngine], i.e. the one precedence
  // in `PlayerEngineIdentity`; this provider adds no branch of its own.
  // Watching the double too keeps the old reactivity contract (its value
  // can never change at runtime, but the watch is free).
  ref.watch(playerEngineRevProvider);
  ref.watch(playerEngineTestDoubleProvider);
  return ref.read(playerControllerProvider.notifier).activeEngine;
});
