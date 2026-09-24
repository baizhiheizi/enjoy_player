/// The single engine-identity resolver: which [PlayerEngine] is live (issue #751).
///
/// "Which engine is live" used to be answered at four sites with two
/// divergent orderings (controller: double-first; surface host: owned-first;
/// vocabulary clip: owned-only; the provider delegated to the controller).
/// This module encodes the precedence **once**:
///
/// 1. **test double** — [playerEngineTestDoubleProvider]; tests only (the
///    provider is always `null` in production). Always wins, so one fake
///    drives transport and the surface host together.
/// 2. **owned engine** — the real engine the swap choreography installs into
///    `PlayerController.ownedEngine`.
/// 3. **lazy default** — the first local/URL need allocates [allocateDefault]
///    (production: `MediaKitPlayerEngine`) into the owned slot. Kept out of
///    widget builds: [resolveOrNull] is the same order truncated before this
///    allocating tail, and it is what build-time consumers (the surface host,
///    the vocabulary clip body) use — a widget build must never construct an
///    engine as a side effect.
///
/// Every identity consumer resolves through this module: the controller's
/// `activeEngine` (and therefore `playerEngineProvider` and the open scope),
/// `PlayerSurfaceHost`, and the vocabulary clip body. With both a test double
/// and an owned engine set — possible only via the `ownedEngine` test seam —
/// everyone resolves the double.
///
/// **Rev ownership:** [playerEngineRevProvider] is this module's *internal*
/// change signal. It is bumped here as the side effect of the owned slot
/// actually changing; callers never hand-bump it. That retires both
/// `EngineSwapCoordinator.bumpRev` and the controller's deferred-microtask
/// bump (issue #751). Install-time changes (the swap choreography's `install`)
/// notify synchronously — existing tests observe the bump in the same turn —
/// while the lazy-default tail defers to a microtask because it can run inside
/// another provider's build (`playerEngineProvider` reading `activeEngine`),
/// and a notification must never land during a provider build. Consumers keep
/// *watching* the rev; how it is produced is now this module's private detail.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_engine.dart';
import 'player_engine_rev.dart';

class PlayerEngineIdentity {
  PlayerEngineIdentity({
    required this.ref,
    required this.owned,
    required this.writeOwned,
    required this.testDouble,
    required this.allocateDefault,
    required this.isDisposed,
  });

  final Ref ref;

  /// Current owned engine — the real-engine slot (null until first install).
  final PlayerEngine? Function() owned;

  /// Raw writer for the owned slot. Only [setOwned] and [resolve]'s lazy tail
  /// should reach it; direct field writes (the `ownedEngine` test seam) bypass
  /// the change signal on purpose, exactly as they always have.
  final void Function(PlayerEngine? next) writeOwned;

  /// The test double (`null` in production).
  final PlayerEngine? Function() testDouble;

  /// Factory for the lazy-default tail (production: `MediaKitPlayerEngine`,
  /// passed by `PlayerController` so the construction site stays there).
  final PlayerEngine Function() allocateDefault;

  /// Whether the owning controller has been disposed — the deferred
  /// notification must not touch `Ref` afterwards.
  final bool Function() isDisposed;

  /// Full precedence resolution for transport paths (controller `activeEngine`,
  /// `playerEngineProvider`, the open choreography): may allocate the lazy
  /// default. Widget builds must use [resolveOrNull] instead.
  PlayerEngine resolve() {
    final injected = testDouble();
    if (injected != null) return injected;
    final current = owned();
    if (current != null) return current;
    return _allocateDefault();
  }

  /// The same precedence as [resolve], truncated before the allocating tail:
  /// test double ?? owned, or `null` when neither exists yet. For build-time
  /// consumers (surface host, vocabulary clip) that must observe identity
  /// without constructing an engine during `build`.
  PlayerEngine? resolveOrNull() => testDouble() ?? owned();

  /// Publishes [next] as the owned engine — the swap choreography's install
  /// path. Bumps the rev synchronously **iff the slot actually changes**: this
  /// change-detection bump replaces `EngineSwapCoordinator.bumpRev` (issue
  /// #751).
  void setOwned(PlayerEngine next) {
    final previous = owned();
    writeOwned(next);
    if (!identical(previous, next)) _notify();
  }

  /// Lazy-default tail of [resolve]: allocates [allocateDefault] into the
  /// owned slot and bumps deferred. The microtask discipline is the old
  /// `_ensureDefaultMediaKitEngine` hack relocated here — this path can run
  /// inside `playerEngineProvider`'s build, and notifying another provider
  /// synchronously from within a build is exactly what Riverpod forbids.
  PlayerEngine _allocateDefault() {
    // resolve() already ruled the double out; re-check so this path can never
    // allocate an engine over a live test double.
    final injected = testDouble();
    if (injected != null) return injected;
    final engine = allocateDefault();
    writeOwned(engine);
    unawaited(
      Future<void>.microtask(() {
        if (isDisposed()) return;
        _notify();
      }),
    );
    return engine;
  }

  void _notify() => ref.read(playerEngineRevProvider.notifier).bump();
}
