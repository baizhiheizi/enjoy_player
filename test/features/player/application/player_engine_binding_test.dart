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
///
/// Because the one-shot bump lives on this engine's `dispose()`, whichever
/// call site disposes it first is the one that fires the bump. The fake
/// therefore records [bumpOrigin] — the stack at the dispose call that
/// bumped — and the tests assert it names the expected call site, so a bump
/// triggered by any other dispose fails while pointing at the actual
/// caller.
class _GenerationBumpingYoutubeEngine extends FakeYoutubeEngine {
  _GenerationBumpingYoutubeEngine(this.onDisposeStarted);

  final void Function() onDisposeStarted;
  bool _bumped = false;

  /// Stack captured inside the dispose call that fired the one-shot bump;
  /// `null` until then.
  StackTrace? bumpOrigin;

  @override
  Future<void> dispose() {
    if (!_bumped) {
      _bumped = true;
      bumpOrigin = StackTrace.current;
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
      expect(container.read(playerEngineRevProvider), revBefore + 1);

      await owned?.dispose();
    },
  );

  test(
    'YouTube to MediaKit swap does not finish until the prior surface detaches',
    () async {
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

    final swapFuture = wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 1,
    );

    await Future<void>.delayed(Duration.zero);
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());

    wiring.bumpGeneration();
    gate.complete();

    final result = await swapFuture;
    expect(result, isFalse, reason: 'superseded swap must return false');
    expect(
      wiring.getOwned(),
      same(prior),
      reason: 'slot must hold the prior engine, not the disposed `next`',
    );
    expect(container.read(playerEngineRevProvider), revBefore + 2);

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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final wiring = _wire(container);

    final prior = FakeYoutubeEngine();
    addTearDown(prior.dispose);
    wiring.setOwned(prior);
    final revBefore = container.read(playerEngineRevProvider);

    final swapFuture = wiring.coordinator.ensureEngineForPlayableSource(
      playable: const LocalFilePlayableSource('file:///tmp/a.mp4'),
      openGeneration: 1,
    );
    expect(wiring.getOwned(), isA<MediaKitPlayerEngine>());
    expect(wiring.getOwned(), isNot(same(prior)));

    wiring.bumpGeneration();

    await Future<void>.delayed(Duration.zero);

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
    expect(container.read(playerEngineRevProvider), revBefore + 2);

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
    expect(
      prior.bumpOrigin?.toString() ?? '',
      contains('discardWithoutAwaiting'),
      reason:
          'the generation bump must come from the swap body\'s '
          '`discardWithoutAwaiting` dispose, not any other teardown. '
          'Recorded bump origin:\n${prior.bumpOrigin}',
    );
    expect(container.read(playerEngineRevProvider), revBefore + 2);

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
