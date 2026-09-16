import 'dart:async';

import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engine_swap_coordinator.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
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
/// the owner slot and the coordinator so tests can drive both sides directly.
({
  PlayerEngine? Function() getOwned,
  void Function(PlayerEngine?) setOwned,
  EngineSwapCoordinator coordinator,
})
_wire(ProviderContainer container) {
  PlayerEngine? owned;
  var openGen = 1;
  final coordinator = EngineSwapCoordinator(
    ref: _refOf(container),
    getOwnedEngine: () => owned,
    setOwnedEngine: (next) => owned = next,
    getActiveEngine: () => owned ?? MediaKitPlayerEngine(),
    currentOpenGeneration: () => openGen,
    abandonPendingOpen: () => openGen++,
  );
  return (
    getOwned: () => owned,
    setOwned: (next) => owned = next,
    coordinator: coordinator,
  );
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
    // Install bump + prepareNativeBackend bump (Video may mount after).
    expect(container.read(playerEngineRevProvider), revBefore + 2);

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
      // Drop-YouTube bump + prepareNativeBackend bump.
      expect(container.read(playerEngineRevProvider), revBefore + 2);

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
}
