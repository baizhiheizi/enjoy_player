/// Abstraction over playback backends: [MediaKitPlayerEngine] (default) and [YouTubePlayerEngine].
///
/// Transport + streams + swap-lifecycle only. What only *some* engines can do
/// (frame capture, embedded-subtitle control, YouTube playback) lives in
/// `player_engine_capabilities.dart` as capability interfaces call sites
/// branch on with `is` (issue #720).
library;

import 'package:enjoy_player/features/player/domain/playable_source.dart';

/// Optional metadata capability of an engine (issue #664).
///
/// Poster plumbing, the identity of the currently-open source, and open-time
/// init instrumentation. Engines that render decoded frames directly
/// ([MediaKitPlayerEngine]) have none of it — [PlayerEngine.metadata] is
/// `null` there and call sites null-check instead of branching on a
/// capability flag or a concrete engine class.
abstract interface class PlayerEngineMetadata {
  /// Poster shown while the surface is loading/buffering; `null` until the
  /// open path resolves one.
  String? get posterUrl;

  void setPosterUrl(String? url);

  /// Id of the currently-open YouTube video; empty when not applicable.
  String get currentVideoId;

  /// Marks the start of open-time init instrumentation.
  void markOpenTimingStart();
}

/// Contract implemented by [MediaKitPlayerEngine] / [YouTubePlayerEngine]; fakes in tests.
///
/// Transport + streams + swap lifecycle only — the members every engine
/// implements identically in kind. Widget building is *not* part of the
/// contract: the presentation layer mounts a per-engine stage for the active
/// engine (see `buildPlayerVideoStage`, issue #664) and reads the non-widget
/// inputs each concrete engine publishes. Source identity, poster plumbing
/// and init timing live behind the optional [PlayerEngineMetadata]
/// capability; frame capture, embedded-subtitle control, and YouTube playback
/// live in `player_engine_capabilities.dart` (issue #720).
abstract class PlayerEngine {
  Stream<Duration> get position;

  Stream<Duration> get duration;

  Stream<bool> get playing;

  Stream<bool> get buffering;

  /// Fires when the current media reaches the end (ADR-0044).
  ///
  /// - **MediaKit**: forwards `media_kit`'s `Player.stream.completed`.
  /// - **YouTube**: synthesized from the HTML5 `<video>` `ended` event / poll
  ///   loop at ~250 ms resolution (ADR-0015).
  ///
  /// May fire duplicate or late events across seeks; callers must guard with a
  /// generation counter (see `PlayerController._playbackGen`).
  Stream<void> get completed;

  /// Completes when the engine's video surface is usable after `open`.
  /// Native engines are ready immediately; the WebView engine awaits mount.
  Future<void> awaitSurfaceReady();

  /// Completes when this engine's platform view has been dropped (or was
  /// never mounted). Used by the YouTube → MediaKit swap so mpv is not
  /// allocated while InAppWebView is still tearing down.
  Future<void> awaitSurfaceDetached();

  /// Allows native backend allocation (MediaKit `[Player]`). YouTube is a
  /// no-op. Must run *after* the previous engine's surface has detached so
  /// the first mpv construct cannot race WebView destroy.
  void prepareNativeBackend();

  /// This engine's [PlayerEngineMetadata] capability, or `null` when it has
  /// none ([MediaKitPlayerEngine]).
  PlayerEngineMetadata? get metadata;

  /// Clears any end-of-media latch so the next [play] drives the loaded
  /// media directly instead of restarting from the beginning. Engines
  /// without a completion latch treat this as a no-op (ADR-0044).
  void resetCompletionFlag();

  /// Teardown used by `PlayerController.clear`. The WebView engine idles and
  /// keeps its process alive (optionally still mounted); native engines stop.
  Future<void> teardownAfterClear({required bool keepSurfaceMounted});

  /// Current transport flags for seeding [StreamProvider]s.
  ({bool playing, bool buffering}) get transportSnapshot;

  /// When false, [PlayerSurfaceHost] unmounts the engine's stage while parked
  /// off-screen. MediaKit's Android `Texture` / Surface stays black if it is
  /// first laid out off-screen; YouTube's WebView must stay mounted.
  bool get keepSurfaceWhenParked;

  Future<void> open(PlayableSource source);

  Future<void> seek(Duration target);

  Future<void> setRate(double rate);

  /// [volume] is 0.0–1.0 (mapped to player units in implementation).
  Future<void> setVolumeNormalized(double volume);

  Future<void> playOrPause();

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  /// YouTube: attach the WebView. MediaKit: no-op — [VideoController] is
  /// created when the on-screen [Video] stage builds.
  void warmVideoSurface();

  Future<void> dispose();
}
