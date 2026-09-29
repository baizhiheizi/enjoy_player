/// Owns [PlaybackSession] state and orchestrates [PlayerEngine] + side services.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/player/application/completion_loop.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/engine_swap_coordinator.dart';
import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_identity.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_coordinator.dart';
import 'package:enjoy_player/features/player/application/player_position_tracker.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/single_flight_gate.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/open_media_options.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'open_media_provider.dart';
import 'playback_session_persister.dart';
import 'player_open_side_effects.dart';
import 'video_poster_capture_service.dart';

part 'player_controller.g.dart';

/// Deterministic end-of-media completion loop (ADR-0044).
///
/// Mirrors the generation-counter + single-flight pattern from
/// [SingleFlightGate]: the transport drives itself off `await`ed completion
/// futures instead of polling the position stream, and every in-flight await
/// captures a generation id so a stale completion from a previous media (or a
/// duplicate `completed` event from mpv) is a no-op.
@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController implements PlayerOpenScope {
  /// The owned engine — a thin view onto [engineIdentity]'s own slot
  /// (issue #751): the module owns the field so precedence is resolved and
  /// stored in one object, and which engine is live overall still resolves
  /// through [engineIdentity] (including a test double — never this getter).
  /// The raw setter is the `n.ownedEngine = fake` test seam and bypasses the
  /// rev change signal on purpose; production installs publish through
  /// [PlayerEngineIdentity.setOwned].
  PlayerEngine? get ownedEngine => engineIdentity.owned;
  set ownedEngine(PlayerEngine? next) => engineIdentity.owned = next;

  /// The one engine-identity resolver (issue #751): precedence
  /// **test double · owned · lazy default**, documented once on
  /// [PlayerEngineIdentity] — which also owns the slot behind [ownedEngine]
  /// and is the sole owner of [playerEngineRevProvider] bumps. It notifies
  /// as the side effect of the owned slot actually changing, so no caller
  /// hand-bumps the rev anymore.
  late final PlayerEngineIdentity engineIdentity = PlayerEngineIdentity(
    bumpRev: () => ref.read(playerEngineRevProvider.notifier).bump(),
    testDouble: () => ref.read(playerEngineTestDoubleProvider),
    allocateDefault: MediaKitPlayerEngine.new,
    isDisposed: () => _disposed,
  );

  late final PlayerPositionTracker _positionTracker = PlayerPositionTracker(
    ref: ref,
    getEngine: () => activeEngine,
    getSession: () => state,
    setSession: (next) => state = next,
    currentOpenGeneration: () => _openGate.generation,
  );

  /// The open generation: bumped by [openMedia], [clear] and
  /// [abandonPendingOpen]; every async step of an open captures it at entry
  /// ([openGeneration] / [isOpenStale]) and bails when it has moved on. The
  /// single-flight slot is unused here — see [EngineSwapCoordinator] for the
  /// swap-in-flight latch (issue #720).
  final SingleFlightGate _openGate = SingleFlightGate();

  /// Sole owner of engine-swap choreography (issue #720): install,
  /// surface-detach wait, wedged-engine replacement, open retry ladder, and
  /// the swap-in-flight latch. Mechanics — what every caller agrees on — live
  /// here; *policy* (clear, abandon, default MediaKit allocation, warm-only
  /// when idle) stays in the controller. Installs publish through
  /// [engineIdentity.setOwned], which bumps the rev as the change side
  /// effect (issue #751) — the coordinator never bumps it itself.
  late final EngineSwapCoordinator _engineSwap = EngineSwapCoordinator(
    ref: ref,
    getOwnedEngine: () => ownedEngine,
    setOwnedEngine: engineIdentity.setOwned,
    getActiveEngine: () => activeEngine,
    currentOpenGeneration: () => _openGate.generation,
    abandonPendingOpen: abandonPendingOpen,
  );

  /// Deterministic end-of-media loop (ADR-0044). Owns the playback
  /// generation counter, the cancelable `completed` await, and the repeat
  /// decision — see [CompletionLoop].
  late final CompletionLoop _completionLoop = CompletionLoop(
    engine: () => activeEngine,
    activeMediaId: () => state?.mediaId,
    isDisposed: () => _disposed,
    repeatMode: () => ref.read(playerPreferencesCtrlProvider).repeatMode,
    echoSnapshot: () {
      final echo = ref.read(echoModeProvider);
      return (active: echo.active, startTimeSeconds: echo.startTimeSeconds);
    },
  );

  bool _disposed = false;

  /// Native (mpv) teardown future, captured so an explicit caller (tests, a
  /// future logout flow) can await disposal. Riverpod's `ref.onDispose` is
  /// synchronous and does NOT await it, so the keepAlive provider must not be
  /// invalidated without coordinating teardown (ADR-0003 / ADR-0015).
  Future<void> _teardown = Future<void>.value();

  Future<void> get teardown => _teardown;

  @override
  int get openGeneration => _openGate.generation;

  @override
  bool isOpenStale(int gen) => _openGate.isStale(gen);

  @override
  PlaybackSession? get session => state;

  @override
  void publishSession(PlaybackSession? next) => state = next;

  @override
  PlayerPositionTracker get positionTracker => _positionTracker;

  /// The single dependency channel of the open scope (issue #750): every
  /// member is a resolver read at open time (lazily built so headless tests
  /// never touch providers they do not use) — nothing here can pin a stale
  /// provider instance across a session switch or a scope change. The two
  /// scheduler closures bind this controller's own `Ref`, which is what
  /// keeps raw `Ref` out of the choreography body.
  @override
  late final PlayerOpenDeps deps = PlayerOpenDeps(
    persister: () => ref.read(playbackSessionPersisterProvider),
    db: () => ref.read(appDatabaseProvider),
    preferences: () => ref.read(playerPreferencesCtrlProvider.notifier),
    echoMode: () => ref.read(echoModeProvider.notifier),
    blurMode: () => ref.read(transcriptBlurModeProvider.notifier),
    posterService: () => ref.read(videoPosterCaptureServiceProvider),
    scheduleOpenSideEffects:
        ({
          required int openGeneration,
          required String mediaId,
          required String dexieTargetType,
        }) => schedulePlayerOpenSideEffects(
          ref,
          openGeneration: openGeneration,
          isStale: () => isOpenStale(openGeneration),
          mediaId: mediaId,
          dexieTargetType: dexieTargetType,
        ),
    scheduleYoutubeMetadata:
        ({
          required int openGeneration,
          required String mediaId,
          required PlayerEngine engine,
        }) => scheduleYoutubeMetadataRefresh(
          ref,
          mediaId: mediaId,
          openGeneration: openGeneration,
          engine: engine,
          currentOpenGeneration: () => this.openGeneration,
          currentSessionMediaId: () => state?.mediaId,
        ),
  );

  /// Engine-swap access for the open scope is exactly the two operations the
  /// choreography uses (issue #750); the swap itself stays owned by
  /// [EngineSwapCoordinator] (issue #720).
  @override
  Future<bool> ensureEngineForPlayableSource({
    required PlayableSource playable,
    required int openGeneration,
  }) => _engineSwap.ensureEngineForPlayableSource(
    playable: playable,
    openGeneration: openGeneration,
  );

  @override
  Future<void> openEngineWithRetry({
    required PlayerEngine engine,
    required PlayableSource playable,
    required int openGeneration,
    required bool swappedAfterInstall,
    required Duration openTimeout,
    required Duration engineCommandTimeout,
  }) => _engineSwap.openEngineWithRetry(
    engine: engine,
    playable: playable,
    openGeneration: openGeneration,
    swappedAfterInstall: swappedAfterInstall,
    openTimeout: openTimeout,
    engineCommandTimeout: engineCommandTimeout,
  );

  /// The live engine — one precedence, resolved by [engineIdentity] (issue
  /// #751): test double, else the owned engine, else the lazy MediaKit
  /// default (allocated here only on this non-build path; widget builds use
  /// `engineIdentity.resolveOrNull()`).
  @override
  PlayerEngine get activeEngine => engineIdentity.resolve();

  PlayerEngine get engine => activeEngine;

  @override
  PlaybackSession? build() {
    final persister = ref.read(playbackSessionPersisterProvider);
    ref.onDispose(() {
      _teardown = _disposeResources(persister);
    });

    return null;
  }

  /// Sequenced, reentrancy-guarded teardown: cancel persistence, the position
  /// tracker (which resets echo enforcement), the completion loop, then the
  /// owned engine. Safe to call more than once.
  Future<void> _disposeResources(PlaybackSessionPersister persister) async {
    if (_disposed) return;
    _disposed = true;
    _completionLoop.bump();
    persister.cancel();
    await _positionTracker.cancel();
    await ownedEngine?.dispose();
  }

  Future<void> relocateAndOpen(String mediaId, XFile picked) async {
    final lib = ref.read(mediaLibraryRepositoryProvider);
    await lib.relocateLocalFile(mediaId: mediaId, picked: picked);
    state = null;
    await openMedia(mediaId);
    ref.invalidate(openMediaActionProvider(mediaId));
    ref.invalidate(
      openMediaLaunchProvider(PlayerLaunchRequest(mediaId: mediaId)),
    );
  }

  Future<void> openMedia(
    String mediaId, {
    OpenMediaOptions options = OpenMediaOptions.defaults,
  }) async {
    if (state?.mediaId == mediaId) {
      if (!options.restoreEcho) {
        ref.read(echoModeProvider.notifier).deactivate();
      }
      unawaited(
        ref.read(mediaLibraryRepositoryProvider).touchMediaUpdatedAt(mediaId),
      );
      return;
    }

    final gen = _openGate.bump();
    _engineSwap.markOpenInFlight();
    _completionLoop.bump();

    try {
      await runPlayerOpenGuarded(
        this,
        mediaId,
        options: options,
        onFailureResetSession: () {
          if (!_openGate.isStale(gen)) {
            state = null;
          }
        },
      );
    } finally {
      _engineSwap.clearOpenInFlightIfCurrent(gen);
    }

    if (!_disposed && !_openGate.isStale(gen) && state?.mediaId == mediaId) {
      _completionLoop.arm();
      unawaited(
        ref.read(mediaLibraryRepositoryProvider).touchMediaUpdatedAt(mediaId),
      );
    }
  }

  Future<void> seekTo(
    Duration target, {
    EchoWindow? echoWindowForSeekClamp,
  }) async {
    _completionLoop.bump();
    final echo = ref.read(echoModeProvider);
    final seconds = secondsFromDuration(target);
    if (decideSeekRouting(echoActive: echo.active)) {
      await _positionTracker.echoEnforcer.clampAndSeek(
        seconds,
        override: echoWindowForSeekClamp,
      );
    } else {
      await activeEngine.seek(durationFromSeconds(seconds));
    }
    _completionLoop.arm();
  }

  Future<void> seekToSeconds(
    double seconds, {
    EchoWindow? echoWindowForSeekClamp,
  }) async {
    await seekTo(
      durationFromSeconds(seconds),
      echoWindowForSeekClamp: echoWindowForSeekClamp,
    );
  }

  Future<void> togglePlay() async {
    await activeEngine.playOrPause();
    _completionLoop.arm();
  }

  Future<void> play() async {
    await activeEngine.play();
    _completionLoop.arm();
  }

  Future<void> clear({bool keepVideoSurface = false}) async {
    _completionLoop.bump();
    await _positionTracker.cancel();

    final current = state;
    final persister = ref.read(playbackSessionPersisterProvider);
    if (current != null) {
      await persister.flush(
        mediaId: current.mediaId,
        dexieTargetType: current.dexieTargetType,
        session: current,
      );
    } else {
      persister.cancel();
    }

    _openGate.bump();
    _engineSwap.clearOpenInFlight();

    final engine = activeEngine;

    ref.read(echoModeProvider.notifier).deactivate();
    ref.read(transcriptBlurModeProvider.notifier).deactivate();
    state = null;

    await engine.teardownAfterClear(keepSurfaceMounted: keepVideoSurface);
  }

  void warmYoutubeSurface() {
    if (ref.read(playerEngineTestDoubleProvider) != null) return;
    if (youTubeEngineOptedOutHere) return;
    if (_disposed || state != null || _engineSwap.isOpenInFlight) return;

    final owned = ownedEngine;
    if (owned != null && owned is YoutubePlaybackEngine) {
      owned.warmVideoSurface();
      return;
    }
    if (owned != null) {
      return;
    }
    _engineSwap.install(YoutubePlayerEngine());
    ownedEngine!.warmVideoSurface();
  }

  void abandonPendingOpen() {
    _openGate.bump();
    _completionLoop.bump();
  }

  /// Called by [PlayerMetadataService] after lazy title/thumbnail refresh.
  void applySessionPatch(PlaybackSession patched) {
    if (state?.mediaId != patched.mediaId) return;
    state = patched;
  }
}
