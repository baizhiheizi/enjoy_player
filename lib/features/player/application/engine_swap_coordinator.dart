/// One owner for the engine swap choreography: install, bump, detach-wait,
/// wedged replacement, open retry ladder, and the open-in-flight latch
/// (issue #720).
///
/// Consolidates what used to be smeared across `player_engine_binding.dart`
/// (swap mechanics + `ensureEngineForPlayableSource` + wedged replacement),
/// the open-coordinator retry ladder, and the controller's `_openInFlight`
/// latch. The protocol is unchanged — this is ownership relocation, not a
/// policy change. *Policy* that is genuinely about session state (whether an
/// open may start at all, what happens on clear) stays in `PlayerController`;
/// everything that coordinates an engine *identity* change lives here.
///
/// Mechanics every engine swap shares: install [PlayerEngine] as the owned
/// engine and bump [playerEngineRevProvider] so the permanent
/// [PlayerSurfaceHost] re-keys its stage (ADR-0057), plus the teardown of the
/// engine that was replaced. Three callers drive them:
///
/// - [ensureEngineForPlayableSource] runs the full open-path choreography:
///   install + bump, let the host drop the old stage, wait for the prior
///   surface to detach, settle, discard the old engine without awaiting it,
///   prepare the native backend, bump again.
/// - `PlayerController.warmYoutubeSurface` installs only when there is no
///   engine at all and never discards the replaced engine — that is what
///   makes its "must never dispose a live / parked MediaKit engine" rule true
///   by construction rather than by an assertion in the call site.
/// - [replaceWedgedLocalEngine] installs a replacement for a wedged local
///   engine and discards the wedged one unawaited.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_coordinator.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';

final _swapLog = logNamed('EngineSwapCoordinator');

class EngineSwapCoordinator {
  EngineSwapCoordinator({
    required this.ref,
    required this._getOwnedEngine,
    required this._setOwnedEngine,
    required this._getActiveEngine,
    required this._currentOpenGeneration,
    required this._abandonPendingOpen,
  });

  final Ref ref;
  final PlayerEngine? Function() _getOwnedEngine;
  final void Function(PlayerEngine? next) _setOwnedEngine;
  final PlayerEngine Function() _getActiveEngine;
  final int Function() _currentOpenGeneration;
  final void Function() _abandonPendingOpen;

  /// True between the open bumping the open generation and the session being
  /// published (or the open failing): `state` is still `null`, so this is the
  /// only signal that an engine swap is already coordinated and in flight.
  /// `PlayerController.warmYoutubeSurface` consults it — issue #657.
  ///
  /// Deliberately *not* the gate's in-flight slot: it is a latch keyed by
  /// generation (cleared in `finally` only when the open is still current, and
  /// cleared unconditionally by `clear()` with no future completing), which is
  /// not the identity-guarded "one op owns the slot" contract the gate models.
  bool _openInFlight = false;

  bool get isOpenInFlight => _openInFlight;

  /// Marks an open as coordinating the engine. Called by
  /// `PlayerController.openMedia` before its first await so a speculative
  /// [warming install] that lands inside this window sees the open that is
  /// already coordinating the engine (issue #657).
  void markOpenInFlight() => _openInFlight = true;

  /// Only a still-current open clears the flag — an open superseded by a
  /// newer one must not report "idle" while that newer one is still running.
  void clearOpenInFlightIfCurrent(int openGeneration) {
    if (_currentOpenGeneration() != openGeneration) return;
    _openInFlight = false;
  }

  /// Clear invalidates any open still in flight, so drop the flag too — that
  /// open's `finally` skips the reset (its generation is stale) and the latch
  /// would otherwise disable speculative warming for the rest of the session
  /// (issue #657).
  void clearOpenInFlight() => _openInFlight = false;

  /// Installs [next] as the owned engine and notifies the surface host.
  /// Returns the engine that was replaced, or `null` when there was none —
  /// the caller owns its teardown, under its own contract.
  PlayerEngine? install(PlayerEngine next) {
    final previous = _getOwnedEngine();
    _setOwnedEngine(next);
    bumpRev();
    return previous;
  }

  /// Notifies [PlayerSurfaceHost] that the engine identity changed.
  ///
  /// [ensureEngineForPlayableSource] bumps **twice**: the first bump drops the
  /// old engine's video stage before teardown, the second follows
  /// [PlayerEngine.prepareNativeBackend] so the MediaKit `Video` may mount
  /// into the already-keyed loading stage.
  void bumpRev() => ref.read(playerEngineRevProvider.notifier).bump();

  /// Waits for [previous]'s platform view to drop (bounded by
  /// [kEngineSurfaceDetachTimeout]) and lets the surface settle
  /// ([kEngineSurfaceSettleDelay]) so MediaKit never allocates [Player] while
  /// InAppWebView is still destroying.
  Future<void> awaitPriorSurfaceSettled(PlayerEngine previous) async {
    try {
      await previous.awaitSurfaceDetached().timeout(
        kEngineSurfaceDetachTimeout,
      );
    } on TimeoutException {
      _swapLog.warning(
        'prior engine surface detach timed out after '
        '$kEngineSurfaceDetachTimeout; continuing swap',
      );
    }
    await Future<void>.delayed(kEngineSurfaceSettleDelay);
  }

  /// Starts [previous]'s teardown without awaiting it.
  ///
  /// YouTube `closeStreams` can hang for seconds while listeners drain
  /// (2026-08-30 Android: 5 s skeleton on a 4 s local file — the log was this
  /// exact timeout). The replacement is already installed; a leaked old
  /// teardown beats a spinner.
  void discardWithoutAwaiting(PlayerEngine previous) {
    unawaited(previous.dispose());
  }

  /// Ensures the owned engine matches [playable] (YouTube vs MediaKit),
  /// bumping [playerEngineRevProvider] when the implementation changes.
  ///
  /// Returns `true` when a new engine was installed (first local open or a
  /// YouTube ↔ MediaKit swap). Returns `false` when the owned engine already
  /// matches, a test double is installed, or the open generation went stale.
  ///
  /// [openGeneration] must match the current generation before and after each
  /// async step so concurrent open calls cannot dispose another call's
  /// engine mid-flight.
  ///
  /// Per ADR-0057, the permanent [PlayerSurfaceHost] keys its stage by engine
  /// identity. We must **swap + bump first** so the host drops the old
  /// video stage, then wait for that surface to detach, *then* allow
  /// MediaKit to allocate mpv — never construct [Player] while InAppWebView
  /// is still tearing down (2026-08-30 field report: local audio after YouTube
  /// stuck on the loading skeleton; back + reopen recovered because the
  /// second open skipped the swap).
  ///
  /// The first local/URL open also installs [MediaKitPlayerEngine] and bumps
  /// so [PlayerSurfaceHost] can mount `Video` before decode starts. Creating
  /// [VideoController] with no [Video] widget binds a native texture that
  /// stays black on Windows/Android until a later layout.
  ///
  /// After-await staleness delegates to the choreography's shared
  /// [OpenSteps] mechanism (issue #750): each guarded step disposes the
  /// not-yet-live replacement through `onSuperseded` and unwinds with
  /// [OpenSupersededException], which this method translates back into the
  /// `false` = "no swap landed" contract.
  Future<bool> ensureEngineForPlayableSource({
    required PlayableSource playable,
    required int openGeneration,
  }) async {
    if (ref.read(playerEngineTestDoubleProvider) != null) return false;
    final steps = OpenSteps(
      isStale: () => _currentOpenGeneration() != openGeneration,
      logWarning: _swapLog.warning,
    );
    if (steps.isStale()) return false;

    final wantYt = playable is YoutubePlayableSource;
    final owned = _getOwnedEngine();
    final haveYt = owned is YoutubePlaybackEngine;

    // ADR-0048 defense in depth: no WebView backend exists on opted-out
    // platforms, so a YouTube engine can never mount. Installing one would
    // dispose the live MediaKit engine (and its native mpv player) for
    // nothing — the 2026-08-29 field report traced every later audio open
    // hanging on the loading skeleton back to exactly that swap. The open
    // coordinator gates YouTube opens before this call; callers that open the
    // source anyway fail with the typed unavailable exception.
    if (wantYt && youTubeEngineOptedOutHere) return false;

    if (owned != null && haveYt == wantYt) return false;
    if (steps.isStale()) return false;

    final next = wantYt ? YoutubePlayerEngine() : MediaKitPlayerEngine();
    install(next);
    // Let PlayerSurfaceHost drop the old ObjectKey stage before teardown.
    // MediaKit must not allocate [Player] yet — [prepareNativeBackend] runs
    // only after the prior surface has detached.
    try {
      await steps.run(
        'yield to surface host',
        () => Future<void>.delayed(Duration.zero),
        onSuperseded: () => next.dispose(),
      );
    } on OpenSupersededException {
      return false;
    }
    if (owned != null) {
      try {
        await steps.run(
          'await prior surface detach',
          () => awaitPriorSurfaceSettled(owned),
          onSuperseded: () => next.dispose(),
        );
      } on OpenSupersededException {
        return false;
      }
      discardWithoutAwaiting(owned);
    }
    if (steps.isStale()) {
      await next.dispose();
      return false;
    }
    next.prepareNativeBackend();
    // Second bump: MediaKit Video may now mount (loading stage already has a
    // target). First bump only dropped the YouTube WebView.
    bumpRev();
    return true;
  }

  /// Replaces a wedged local/URL engine with a fresh [MediaKitPlayerEngine].
  ///
  /// The timed-out `open` on the owned engine is still in flight — do not
  /// await its dispose. No-op when a test double is installed so unit tests
  /// retry the same fake.
  Future<void> replaceWedgedLocalEngine() async {
    if (ref.read(playerEngineTestDoubleProvider) != null) return;
    final old = _getOwnedEngine();
    if (old == null || old is YoutubePlaybackEngine) return;
    final next = MediaKitPlayerEngine();
    next.prepareNativeBackend();
    install(next);
    discardWithoutAwaiting(old);
  }

  /// Drives `engine.open` with the wedged-open retry ladder.
  ///
  /// After a YouTube → MediaKit swap the first `open` races WebView
  /// teardown and can hang (2026-08-30: skeleton until back + reopen).
  /// Use the short command ceiling for that first attempt, then retry
  /// once — reopen works because the native side has settled / a fresh
  /// player is installed. A timeout must not fail the open on try 1.
  Future<void> openEngineWithRetry({
    required PlayerEngine engine,
    required PlayableSource playable,
    required int openGeneration,
    required bool swappedAfterInstall,
    required Duration openTimeout,
    required Duration engineCommandTimeout,
  }) async {
    // The open attempts keep their explicit `.timeout` ladder (a timeout here
    // drives the retry, it is not a swallowed wedge), but the staleness query
    // delegates to the shared guarded-step mechanism (issue #750). The caller
    // guards the return, which is what stops the engine when this open is
    // superseded after a successful open.
    final steps = OpenSteps(
      isStale: () => _currentOpenGeneration() != openGeneration,
      logWarning: _swapLog.warning,
    );
    final firstTimeout = swappedAfterInstall
        ? engineCommandTimeout
        : openTimeout;
    try {
      await engine.open(playable).timeout(firstTimeout);
    } on TimeoutException {
      _swapLog.warning(
        'engine.open timed out after $firstTimeout '
        '(${engine.runtimeType}); retrying once',
      );
      await replaceWedgedLocalEngine();
      if (steps.isStale()) return;
      final retryEngine = _getActiveEngine();
      try {
        await retryEngine.open(playable).timeout(openTimeout);
      } on TimeoutException {
        _swapLog.severe(
          'engine.open retry timed out after $openTimeout '
          '(${retryEngine.runtimeType}); invalidating open generation',
        );
        _abandonPendingOpen();
        rethrow;
      }
    }
  }
}
