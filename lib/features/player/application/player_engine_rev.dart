/// Change counter bumped by `PlayerEngineIdentity` when the resolved engine
/// identity actually changes, so consumers re-watch (issue #751).
///
/// An internal detail of the identity module: callers never bump it directly
/// anymore (`EngineSwapCoordinator.bumpRev` and the controller's
/// deferred-microtask bump are gone). `PlayerSurfaceHost` and
/// `playerEngineProvider` keep watching it purely as a reactivity signal.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_engine_rev.g.dart';

@Riverpod(keepAlive: true)
class PlayerEngineRev extends _$PlayerEngineRev {
  @override
  int build() => 0;

  void bump() => state++;
}
