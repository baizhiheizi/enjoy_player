import 'dart:async';

import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engine_swap_coordinator.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_identity.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_player_engine.dart';

/// Captures the [Ref] of an ad-hoc provider inside a [ProviderContainer].
Ref _refOf(ProviderContainer container) {
  late Ref captured;
  container.read(
    Provider<int>((ref) {
      captured = ref;
      return 0;
    }),
  );
  return captured;
}

/// Mounts a coordinator in [container] with the given initial owner. Returns
/// the owned slot and the coordinator so tests can drive both sides directly.
///
/// Everything routes through a real [PlayerEngineIdentity] (issue #751): the
/// identity module *owns* the slot, is the sole owner of
/// [playerEngineRevProvider] bumps (the rev moves once per actual change of
/// the owned slot), and answers every precedence question — the coordinator
/// reads the slot via [PlayerEngineIdentity.owned] and resolves active
/// engines via [PlayerEngineIdentity.resolve], never a hand-rolled
/// `owned ?? default`. The raw `setOwned` returned here writes the module's
/// slot directly — the direct test seam (no notification), mirroring the
/// `controller.ownedEngine = …` writes in the controller tests.
///
/// [bumpGeneration] is the test seam to drive a supersede from outside the
/// coordinator (issue #774, item 1): while the swap is parked at a guarded
/// step, the test bumps the generation and then releases the gate, so the
/// parked step sees a stale `isStale()` post-await and the swap unwinds with
/// [OpenSupersededException].
({
  PlayerEngine? Function() getOwned,
  void Function(PlayerEngine) setOwned,
  EngineSwapCoordinator coordinator,
  void Function() bumpGeneration,
})
_wire(ProviderContainer container) {
  var openGen = 1;
  final ref = _refOf(container);
  final identity = PlayerEngineIdentity(
    bumpRev: () => container.read(playerEngineRevProvider.notifier).bump(),
    testDouble: () => container.read(playerEngineTestDoubleProvider),
    allocateDefault: MediaKitPlayerEngine.new,
    isDisposed: () => false,
  );
  final coordinator = EngineSwapCoordinator(
    ref: ref,
    getOwnedEngine: () => identity.owned,
    setOwnedEngine: identity.setOwned,
    getActiveEngine: identity.resolve,
    currentOpenGeneration: () => openGen,
    abandonPendingOpen: () => openGen++,
  );
  return (
    getOwned: () => identity.owned,
    setOwned: (next) => identity.owned = next,
    coordinator: coordinator,
    bumpGeneration: () => openGen++,
  );
}

/// YouTube fake whose first [FakePlayerEngine.dispose] synchronous prefix
/// runs [onDisposeStarted] — scripting the race the swap's trailing
/// staleness check guards: a newer open bumps the generation between the
/// guarded surface-detach step completing and the post-discard check. The
/// coordinator fires `discardWithoutAwaiting(prior)` there, so hooking the
/// first dispose prefix bumps the generation at exactly that point without
/// any polling. One-shot so the fresh verification open below can discard
/// the same prior engine without superseding itself.
class _GenerationBumpingYoutubeEngine extends FakeYoutubeEngine {
  _GenerationBumpingYoutubeEngine(this.onDisposeStarted);

  final void Function() onDisposeStarted;
  bool _bumped = false;

  @override
  Future<void> dispose() {
    if (!_bumped) {
      _bumped = true;
      onDisposeStarted();
    }
    return super.dispose();
  }
}

void main() {
  test('first local open installs MediaKit and bumps engine rev', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final wiring = _wire(container);

    final revBefore = container.read(playerEngineRevProvider);

    await wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 1,
    );

    final owned = wiring.getOwned();
    expect(owned, isA<MediaKitPlayerEngine>());
    expect(owned!.keepSurfaceWhenParked, isFalse);
    // One identity change (null → MediaKit), bumped by PlayerEngineIdentity —
    // issue #751. The old "install bump + prepareNativeBackend bump" (+2) is
    // retired: Video mounts after prepare through the engine's
    // nativeBackendAllowed listenable, not a second rev bump. Intent kept:
    // consumers re-watch on identity change.
    expect(container.read(playerEngineRevProvider), revBefore + 1);

    await owned.dispose();
  });

  test(
    'local open with MediaKit already owned does not bump or replace',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wiring = _wire(container);

      final existing = MediaKitPlayerEngine();
      addTearDown(existing.dispose);
      wiring.setOwned(existing);
      final revBefore = container.read(playerEngineRevProvider);

      await wiring.coordinator.ensureEngineForPlayableSource(
        playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
        openGeneration: 1,
      );

      expect(wiring.getOwned(), same(existing));
      expect(container.read(playerEngineRevProvider), revBefore);
    },
  );

  test(
    'YouTube to MediaKit swap installs MediaKit, bumps, and disposes YouTube',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wiring = _wire(container);

      final youtube = YoutubePlayerEngine();
      wiring.setOwned(youtube);
      final revBefore = container.read(playerEngineRevProvider);

      await wiring.coordinator.ensureEngineForPlayableSource(
        playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
        openGeneration: 1,
      );

      final owned = wiring.getOwned();
      expect(owned, isA<MediaKitPlayerEngine>());
      expect(owned, isNot(same(youtube)));
      // One identity change (YouTube → MediaKit) — the old +2 collapsed to
      // +1 once the stage-mount signal moved to the engine (issue #751).
      expect(container.read(playerEngineRevProvider), revBefore + 1);

      await owned?.dispose();
    },
  );

  test(
    'YouTube to MediaKit swap does not finish until the prior surface detaches',
    () async {
      // 2026-08-30: allocating mk.Player while InAppWebView is still
      // destroying wedges the first local open. The swap must wait.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wiring = _wire(container);

      final gate = Completer<void>();
      final prior = FakeYoutubeEngine()..surfaceDetachGate = gate;
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        await prior.dispose();
      });
      wiring.setOwned(prior);

      final done = Completer<void>();
      unawaited(
        wiring.coordinator
            .ensureEngineForPlayableSource(
              playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
              openGeneration: 1,
            )
            .then((_) => done.complete()),
      );

      await pumpEventQueue();
      expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
      expect(done.isCompleted, isFalse, reason: 'must wait for WebView detach');

      gate.complete();
      await done.future;
      expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
      await wiring.getOwned()?.dispose();
    },
  );

  test(
    'YouTube to MediaKit swap does not wait for a hanging prior dispose',
    () async {
      // Field log 2026-08-30: awaiting YouTube dispose held the loading
      // skeleton for the full 5 s command timeout on a 4 s local file.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wiring = _wire(container);

      final hang = Completer<void>();
      final prior = FakeYoutubeEngine()..disposeGate = hang;
      addTearDown(() {
        if (!hang.isCompleted) hang.complete();
      });
      wiring.setOwned(prior);

      await wiring.coordinator
          .ensureEngineForPlayableSource(
            playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
            openGeneration: 1,
          )
          .timeout(const Duration(seconds: 1));

      expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
      await wiring.getOwned()?.dispose();
    },
  );

  test(
    'opted-out Linux never swaps the live MediaKit engine for YouTube',
    () async {
      // 2026-08-29 field report regression guard: the Linux YouTube open used
      // to swap in YoutubePlayerEngine (disposing the live MediaKit/mpv
      // player); the open then threw, and every later audio open rebuilt
      // MediaKit against a wedged native layer — infinite loading. The open
      // coordinator now gates before this call; the swap itself must stay
      // a no-op for YouTube sources on opted-out platforms as well.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final wiring = _wire(container);

      final existing = MediaKitPlayerEngine();
      addTearDown(existing.dispose);
      wiring.setOwned(existing);
      final revBefore = container.read(playerEngineRevProvider);

      await wiring.coordinator.ensureEngineForPlayableSource(
        playable: const YoutubePlayableSource('dQw4w9WgXcQ'),
        openGeneration: 1,
      );

      expect(wiring.getOwned(), same(existing));
      expect(container.read(playerEngineRevProvider), revBefore);
    },
  );

  test('superseded swap restores the prior owned engine instead of leaving '
      'a disposed replacement in the slot (issue #774, item 1)', () async {
    // Repro: a concurrent newer open (or clear) bumps the open generation
    // while this swap is awaiting the prior surface detach. Before the
    // fix, `next` was installed and disposed but never removed from the
    // slot, so a subsequent open took the
    // `owned != null && haveYt == wantYt → return false` fast path
    // against a disposed engine. The fix restores `owned` on every
    // superseded exit so the slot never holds a disposed engine.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final wiring = _wire(container);

    final gate = Completer<void>();
    final prior = FakeYoutubeEngine()..surfaceDetachGate = gate;
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await prior.dispose();
    });
    wiring.setOwned(prior);
    final revBefore = container.read(playerEngineRevProvider);

    // Start the swap; it installs MediaKit, parks at `awaitPriorSurfaceSettled`
    // because `gate` is not completed.
    final swapFuture = wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 1,
    );

    // Wait until the swap is parked (gate is being awaited). One zero-
    // duration delay is enough — the surface detach `await gate.future` is
    // the only suspend point at this stage.
    await Future<void>.delayed(Duration.zero);
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());

    // Bump the generation (simulating a newer open / clear). The parked
    // step's post-await stale check will now see `isStale()` and throw
    // [OpenSupersededException]; the swap coordinator's catch restores
    // the prior owned engine.
    wiring.bumpGeneration();
    gate.complete();

    final result = await swapFuture;
    expect(result, isFalse, reason: 'superseded swap must return false');
    expect(
      wiring.getOwned(),
      same(prior),
      reason: 'slot must hold the prior engine, not the disposed `next`',
    );
    // The swap installed MediaKit (slot changed) then restored YouTube
    // (slot changed back) — rev moves by +2.
    expect(container.read(playerEngineRevProvider), revBefore + 2);

    // A fresh open of the same kind must NOT take the disposed-engine
    // fast path: the slot holds a live YouTube (not MediaKit, not null),
    // so the swap installs MediaKit fresh and bumps rev by +1.
    final fresh = await wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 2,
    );
    expect(fresh, isTrue);
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
    expect(wiring.getOwned(), isNot(same(prior)));
    await wiring.getOwned()?.dispose();
  });

  test('supersede at the FIRST guarded step (yield to surface host) runs '
      'the same unwind as the detach stage (issue #794 candidate 7)', () async {
    // The #774 fix restated "dispose the replacement, restore the prior
    // owned engine" inline at each supersede exit; its test pinned only the
    // surface-detach exit. The unwind now lives in one place wrapping every
    // guarded step, so this drives a supersede at the FIRST guarded step
    // (the zero-duration yield to the surface host) and pins the same
    // invariant: no disposed engine left in the slot, prior engine kept
    // alive, exactly one install + one restore identity change.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final wiring = _wire(container);

    final prior = FakeYoutubeEngine();
    addTearDown(prior.dispose);
    wiring.setOwned(prior);
    final revBefore = container.read(playerEngineRevProvider);

    // Start the swap: the install is synchronous, so the slot already holds
    // the replacement while the swap parks at the zero-duration yield step.
    final swapFuture = wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 1,
    );
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
    expect(wiring.getOwned(), isNot(same(prior)));

    // A newer open / clear bumps the generation before the yield resolves —
    // still synchronous test code, so no timer can have fired yet.
    wiring.bumpGeneration();

    final result = await swapFuture;
    expect(result, isFalse, reason: 'superseded swap must return false');
    expect(
      wiring.getOwned(),
      same(prior),
      reason: 'slot must hold the prior engine, not the disposed `next`',
    );
    expect(
      prior.disposeCallCount,
      0,
      reason:
          'a swap superseded before the detach stage must not tear the '
          'prior engine down',
    );
    // Exactly one identity change per slot write: install + single restore.
    expect(container.read(playerEngineRevProvider), revBefore + 2);

    // The #774 regression shape: a fresh same-kind open must not take the
    // disposed-engine fast path — it swaps in a new engine and succeeds.
    final fresh = await wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 2,
    );
    expect(fresh, isTrue);
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
    expect(wiring.getOwned(), isNot(same(prior)));
    await wiring.getOwned()?.dispose();
  });

  test('supersede detected at the trailing post-discard check still '
      'restores the prior engine through the single unwind (issue #794 '
      'candidate 7)', () async {
    // The third supersede exit fires when the generation moves after the
    // guarded surface-detach step completed but before the swap finishes —
    // scripted here by a prior engine whose unawaited dispose (fired by
    // `discardWithoutAwaiting` at exactly that point) bumps the generation.
    // Pinned behavior, preserved verbatim by the single-unwind refactor:
    // the swap disposes the replacement and restores the prior engine to
    // the slot even though its teardown was already started unawaited, and
    // a fresh open of the other kind still swaps in a live engine instead
    // of taking the fast path against a disposed one.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final wiring = _wire(container);

    final prior = _GenerationBumpingYoutubeEngine(wiring.bumpGeneration);
    wiring.setOwned(prior);
    final revBefore = container.read(playerEngineRevProvider);

    final result = await wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 1,
    );

    expect(result, isFalse, reason: 'superseded swap must return false');
    expect(
      wiring.getOwned(),
      same(prior),
      reason: 'slot must hold the prior engine, not the disposed `next`',
    );
    expect(
      prior.disposeCallCount,
      1,
      reason:
          'the discard fired before the trailing check observed the '
          'bump — the restore deliberately puts the prior engine back even '
          'though its unawaited teardown started',
    );
    // Install + single restore — the one unwind path is the only writer
    // after the initial install.
    expect(container.read(playerEngineRevProvider), revBefore + 2);

    // Fresh open must not fast-path against a slot it cannot use: the prior
    // engine is the wrong kind, so the swap installs a new live engine.
    final fresh = await wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 2,
    );
    expect(fresh, isTrue);
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
    expect(wiring.getOwned(), isNot(same(prior)));
    await wiring.getOwned()?.dispose();
  });
}
