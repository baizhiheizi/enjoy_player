/// Playback state and broadcast streams for [YoutubePlayerEngine].
///
/// The session owns the Dart-side transport latches; every other module
/// (engine, events, poll loop, webview controller, navigation) changes them
/// only through the transition verbs of this library, so each invariant —
/// what must be cleared together, what may only transition once — is
/// enforced in exactly one place instead of at every writer (issue #627).
///
/// The one exception is the immediate-pause retry protocol (D8/D9), which is
/// too restless to keep inline: its budget, attribution, escalation, and
/// clocks live in the composed [playRetry] policy (issue #665), and the verbs
/// below delegate to it so transport intents still enter through this class.
///
/// ## Composition (issue #721)
///
/// The audible-start choreography ([audibility]) and the DOM poll loop
/// ([pollLoop]) are session-owned: their decisions are about *playback truth*
/// (mute/restore/heal, retry budget), so they live here, not in the WebView
/// lifecycle layer. The [YoutubeWebViewController] attaches them via
/// [attachWebView] once the WebView is wired (the policies need the
/// WebView controller getter; the audibility's web-bound callbacks stay
/// lazy until the attachment is set). The engine and webView controller
/// no longer import the policy classes directly — they reach them through
/// this object.
///
/// ## File layout (issue #1093)
///
/// Shared run state lives in [YoutubeSessionBase]; one mixin per concern
/// (WebView mount lifecycle, watch-document expectations, tap-to-play hint,
/// event bus, volume restore, transport) lives in a sibling `part` file and
/// composes onto it, following the `vocabulary_review_session` layout. The
/// [YoutubeSession] application order is load-bearing:
/// [YoutubeSessionWatchNavigation] precedes [YoutubeSessionHint] (the hint
/// reads the first-playing latch) and [YoutubeSessionHint] precedes
/// [YoutubeSessionEvents] (emits drive the hint); [YoutubeSessionTransport]
/// comes last because its verbs touch every other concern.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_audible_playback_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_monotonic_clock.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_play_retry_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session_web_attachment.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_poll_loop.dart';

export 'package:enjoy_player/features/player/application/engines/youtube/youtube_session_web_attachment.dart';

part 'youtube_session_events.dart';
part 'youtube_session_hint.dart';
part 'youtube_session_transport.dart';
part 'youtube_session_volume_restore.dart';
part 'youtube_session_watch_navigation.dart';
part 'youtube_session_webview_lifecycle.dart';

/// Run-scoped state shared by every concern mixin.
mixin YoutubeSessionBase {
  /// The immediate-pause retry protocol: budget, attribution, escalation,
  /// and its monotonic clocks. Storage verbs below delegate here; the poll
  /// loop and engine read the protocol's decisions from it directly.
  late final YouTubePlayRetryPolicy playRetry;

  String _videoId = '';
  String? _posterUrl;
  bool _disposed = false;
  bool _playbackCompleted = false;

  bool _playing = false;
  bool _buffering = true;

  /// User (or app) requested play; cancels autoplay assist and arms recovery UX.
  bool _explicitPlayAttempted = false;

  int _pausedPollStreak = 0;

  /// Audible-start choreography — owns mute/restore/heal.
  late final YoutubeAudiblePlaybackPolicy _audibility;

  /// DOM poll loop — owned by session; wired in [attachWebView].
  YoutubeWebViewPollLoop? _pollLoop;

  /// WebView attachment for session-owned machinery. Set by
  /// [attachWebView] once the WebView controller is ready; null before.
  YoutubeSessionWebAttachment? _webAttachment;

  String get videoId => _videoId;
  String? get posterUrl => _posterUrl;
  bool get playing => _playing;
  bool get buffering => _buffering;
  bool get disposed => _disposed;
  bool get playbackCompleted => _playbackCompleted;
  bool get explicitPlayAttempted => _explicitPlayAttempted;

  /// Audible-start choreography owner. Read-only — owned by session.
  YoutubeAudiblePlaybackPolicy get audibility => _audibility;

  /// DOM poll loop. Throws [StateError] if accessed before [attachWebView].
  YoutubeWebViewPollLoop get pollLoop {
    final loop = _pollLoop;
    if (loop == null) {
      throw StateError('YoutubeSession.pollLoop accessed before attachWebView');
    }
    return loop;
  }

  /// True when a pause confirmation arrives soon after playback started —
  /// measured on the retry protocol's monotonic clock.
  bool isImmediatePause() => playRetry.isImmediatePause();
}

/// Owns YouTube open state, transport snapshot, and engine event streams.
class YoutubeSession
    with
        YoutubeSessionBase,
        YoutubeSessionWebViewLifecycle,
        YoutubeSessionWatchNavigation,
        YoutubeSessionHint,
        YoutubeSessionEvents,
        YoutubeSessionVolumeRestore,
        YoutubeSessionTransport {
  /// [playRetry], [audibilityClock], [volumeRestoreDelay],
  /// [volumeRestoreFallback], and [postRestoreHealDelay] are injectable so
  /// tests can shorten the protocol windows deterministically.
  YoutubeSession({
    YouTubePlayRetryPolicy? playRetry,
    MonotonicClock? audibilityClock,
    Duration? volumeRestoreDelay,
    Duration? volumeRestoreFallback,
    Duration? postRestoreHealDelay,
  }) {
    this.playRetry = playRetry ?? YouTubePlayRetryPolicy();
    _audibility = YoutubeAudiblePlaybackPolicy(
      session: this,
      reapplyVolume: _reapplyVolumeViaAttachment,
      healPlay: _healPlayViaAttachment,
      clock: audibilityClock,
      volumeRestoreDelay: volumeRestoreDelay,
      volumeRestoreFallback: volumeRestoreFallback,
      postRestoreHealDelay: postRestoreHealDelay,
    );
  }

  /// Recovery-overlay delay. Part of the audible-playback joint invariant
  /// (must exceed [YoutubeAudiblePlaybackPolicy.postRestoreHealDelay]'s
  /// check window) — asserted in the policy's tests, which is why it is
  /// public.
  static const Duration tapToPlayHintDelay = Duration(milliseconds: 1200);

  /// Volume-restore progress gate (poll ticks of confirmed advancement).
  static const int progressConfirmTicks = 2;

  /// Poll-loop pause confirmation threshold.
  static const int pauseConfirmPollTicks = 3;

  /// Wires the session's DOM poll loop to a WebView controller.
  ///
  /// The poll loop needs the controller getter and the first-playing ack;
  /// the audibility's web-bound callbacks (reapplyVolume, healPlay) stay
  /// lazy and resolve through [attachment]. Idempotent — calling twice
  /// replaces the previous poll loop (the WebView lifecycle never needs
  /// to attach twice in practice, but tests may swap fakes); a replaced
  /// loop is stopped first so a running timer chain cannot outlive its
  /// attachment and keep polling the stale controller.
  void attachWebView(YoutubeSessionWebAttachment attachment) {
    _webAttachment = attachment;
    _pollLoop?.stop();
    _pollLoop = YoutubeWebViewPollLoop(
      session: this,
      jsChannel: attachment.jsChannel,
      onFirstPlaying: attachment.onFirstPlaying,
      onPlaybackProgress: _audibility.onPlaybackProgress,
    );
  }

  Future<void> _reapplyVolumeViaAttachment() async {
    final attachment = _webAttachment;
    if (attachment == null) return;
    await attachment.reapplyVolume();
  }

  Future<void> _healPlayViaAttachment() async {
    final attachment = _webAttachment;
    if (attachment == null) return;
    await attachment.healPlay();
  }

  void setPosterUrl(String? url) => _posterUrl = url;
}
