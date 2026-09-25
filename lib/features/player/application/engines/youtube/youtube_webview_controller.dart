/// WebView lifecycle, navigation, and DOM polling for [YoutubePlayerEngine].
///
/// Composition (issue #721): the audible-start policy and the DOM poll loop
/// are owned by [YoutubeSession] now — they reason about playback truth, not
/// WebView lifecycle. The controller's only composition is the events,
/// navigation, and stall watchdog (the WebView-bound observers), and it
/// hands the session the WebView controller getter via
/// [YoutubeSession.attachWebView] so the session-owned poll loop can poll.
library;

import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_js_channel.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_page_inject.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_playback_stall_watchdog.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_watch_navigation_policy.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_video_event.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_events.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_navigation.dart';

final _logWebView = logNamed('YouTubeWebViewController');

/// Manages [InAppWebView] attach/load/poll for one [YoutubeSession].
class YoutubeWebViewController {
  YoutubeWebViewController({
    required this.session,
    required this.onStallRecovery,
    required this.onLogInitPhase,
  }) : _stallWatchdog = YoutubePlaybackStallWatchdog(
         timeout: const Duration(seconds: 12),
         onStall: (videoId) {
           if (session.playing) return;
           _logWebView.warning(
             'youtube playback stalled after load_stop vid=$videoId',
           );
           unawaited(onStallRecovery());
         },
       ) {
    // The audible policy lives on the session now; the events / navigation
    // observers stay here because they need WebView-bound actions
    // (seekTo, controller-lookups, generation bumps).
    _events = YoutubeWebViewEvents(
      session: session,
      jsChannel: () => jsChannel,
      onFirstPlaying: onFirstPlayingFromSession,
      startPolling: () => session.pollLoop.start(),
      stopPolling: () => session.pollLoop.stop(),
      seekTo: (d) => YoutubeWebViewBridge.seekToSeconds(
        jsChannel,
        d.inMilliseconds / 1000.0,
      ),
      audibility: session.audibility,
    );
    _navigation = YoutubeWebViewNavigation(
      session: session,
      jsChannel: () => jsChannel,
      captureVerifyGeneration: () => _verifyGeneration,
      isVerifyGenerationStale: (gen) => gen != _verifyGeneration,
      bumpNavGeneration: () => ++_navGeneration,
      currentNavGeneration: () => _navGeneration,
      onStaleWebView: () {
        attach(null);
        session.noteWebViewUnmounted();
        session.pollLoop.stop();
        session.bumpMountTick();
      },
    );
    // Wire the session's poll loop to this controller. The poll loop
    // lives on the session; the controller is its attachment.
    session.attachWebView(_attachment());
  }

  final YoutubeSession session;
  final Future<void> Function() onStallRecovery;
  final void Function(String phase) onLogInitPhase;

  static const int maxStallRecoveries = 1;

  final YoutubePlaybackStallWatchdog _stallWatchdog;
  late final YoutubeWebViewEvents _events;
  late final YoutubeWebViewNavigation _navigation;

  /// The attached WebView as ONE piece of state: the plugin controller and
  /// its channel wrapper are two views of the same attachment, so they are
  /// stored together (issue #767 review) — there is no second field to drift
  /// out of lockstep, and [attach] is the only writer.
  ({InAppWebViewController controller, YoutubeJsChannel channel})?
  _attachedWebView;
  int _verifyGeneration = 0;
  int _navGeneration = 0;
  int _stallRecoveryCount = 0;
  bool _rejectingNativeFullscreen = false;

  /// The plugin controller, for the WebView lifecycle owner only (handler
  /// registration, widget callbacks, stale-controller identity checks).
  InAppWebViewController? get webController => _attachedWebView?.controller;

  /// The JS-channel view of the attached WebView — what the engine cluster
  /// (events, navigation, poll loop, transport) crosses instead of the
  /// plugin type (issue #767).
  ///
  /// Cached per attachment (not re-wrapped per call) so identity checks on
  /// the channel still mean "same WebView".
  YoutubeJsChannel? get jsChannel => _attachedWebView?.channel;

  /// Attaches (or, with null, detaches) the WebView. The only writer of
  /// [_attachedWebView].
  void attach(InAppWebViewController? controller) {
    _attachedWebView = controller == null
        ? null
        : (controller: controller, channel: InAppWebViewJsChannel(controller));
  }

  // ---------------------------------------------------------------------------
  // YoutubeSessionWebAttachment — the session's WebView controller getter and
  // first-playing ack live here.
  // ---------------------------------------------------------------------------

  /// Adapts this controller to the session's attachment contract. Kept as a
  /// method (not a stored field) so the lambda always reads the latest
  /// [jsChannel].
  YoutubeSessionWebAttachment _attachment() {
    return YoutubeSessionWebAttachment(
      jsChannel: () => jsChannel,
      onFirstPlaying: onFirstPlayingFromSession,
      reapplyVolume: () async {
        await YoutubeWebViewBridge.setVolume(
          jsChannel,
          session.volumeNormalized,
        );
      },
      healPlay: () async {
        await YoutubeWebViewBridge.play(jsChannel);
      },
    );
  }

  void markOpenTimingStart() {
    _stallWatchdog.cancel();
    _navigation.cancelNudge();
    session.audibility.cancelPending();
    _bumpVerifyGeneration();
    session.startInitTiming();
    session.resetWatchPageExpectations(firstPlaying: true);
    _stallRecoveryCount = 0;
    onLogInitPhase('open_start');
  }

  void prepareWatchReload({
    required bool resetFirstPlaying,
    bool resetStallRecovery = true,
  }) {
    _stallWatchdog.cancel();
    _navigation.cancelNudge();
    session.audibility.cancelPending();
    _bumpVerifyGeneration();
    session.resetWatchPageExpectations(firstPlaying: resetFirstPlaying);
    if (resetStallRecovery) {
      _stallRecoveryCount = 0;
    }
  }

  void onFirstPlayingFromSession() {
    _stallWatchdog.onFirstPlaying();
    if (!session.loggedFirstPlaying) {
      session.markFirstPlayingLogged();
      _navigation.cancelNudge();
      onLogInitPhase('first_playing');
    }
  }

  /// Cancels autoplay assist (nudge / stall reload) around an explicit play.
  void onExplicitPlayAttempt() {
    session.markExplicitPlayAttempt();
    _navigation.cancelNudge();
    _stallWatchdog.cancel();
    session.pollLoop.start();
  }

  Future<void> idleAfterClear({bool keepMounted = false}) async {
    _stallWatchdog.cancel();
    _navigation.cancelNudge();
    session.audibility.cancelPending();
    _bumpVerifyGeneration();
    session.resetForClear(keepMounted: keepMounted);
    session.pollLoop.stop();
    final navGen = ++_navGeneration;
    final controller = webController;
    if (controller == null) return;
    try {
      await YoutubeWebViewBridge.loadIdlePage(
        jsChannel,
      ).timeout(kEngineCommandTimeout);
    } on TimeoutException {
      _logWebView.warning(
        'loadIdlePage timed out after $kEngineCommandTimeout; '
        'continuing teardown',
      );
    }
    if (_navGeneration != navGen &&
        session.videoId.isNotEmpty &&
        identical(webController, controller)) {
      unawaited(_navigation.loadCurrentVideoIfAttached());
    }
  }

  Future<void> dispose() async {
    _stallWatchdog.cancel();
    _navigation.cancelNudge();
    session.audibility.cancelPending();
    _bumpVerifyGeneration();
    session.pollLoop.stop();
  }

  Future<void> onSignInNavigationBlocked(InAppWebViewController controller) =>
      _navigation.onSignInNavigationBlocked(
        InAppWebViewJsChannel(controller),
        prepareWatchReload: () => prepareWatchReload(resetFirstPlaying: false),
      );

  /// Main-frame HTTP failures are worth a diagnostic line; sub-frame noise is
  /// not. Called by [YoutubeWebViewHost].
  void onWebResourceHttpError({
    required String? url,
    required int? statusCode,
    required bool isForMainFrame,
  }) {
    if (!isForMainFrame) return;
    _logWebView.warning('youtube main-frame HTTP $statusCode url=${url ?? ''}');
  }

  /// Main-frame load failures (DNS, TLS, …). Called by [YoutubeWebViewHost].
  void onWebResourceLoadError({
    required String url,
    required String description,
  }) {
    _logWebView.warning('youtube load error url=$url msg=$description');
  }

  Future<void> onWebViewProcessTerminated() =>
      _navigation.onWebViewProcessTerminated(
        prepareWatchReload: () => prepareWatchReload(resetFirstPlaying: true),
      );

  void onWebViewCreated(
    InAppWebViewController controller, {
    bool initialWatchUrlRequested = false,
  }) {
    attach(controller);
    session.noteWebViewMounted();
    onLogInitPhase('webview_created');

    if (initialWatchUrlRequested && session.videoId.isNotEmpty) {
      session.noteAwaitingColdInitialNavigation();
    }

    controller.addJavaScriptHandler(
      handlerName: YoutubeJsHandlerName.onAdReload,
      callback: (List<dynamic> args) {
        if (args.isNotEmpty) {
          session.setPendingSeekSeconds((args[0] as num?)?.toDouble() ?? 0);
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: YoutubeJsHandlerName.onVideoEvent,
      callback: _events.handle,
    );

    if (session.videoId.isNotEmpty && !initialWatchUrlRequested) {
      unawaited(_navigation.loadCurrentVideoIfAttached());
      unawaited(
        _navigation.ensureWatchPageLoadedAfterDelay(
          skipIfLoadStopReceived: true,
        ),
      );
    } else if (session.videoId.isNotEmpty) {
      unawaited(
        _navigation.ensureWatchPageLoadedAfterDelay(
          delay: YoutubeWebViewNavigation.coldMountVerifyDelay,
          skipIfLoadStopReceived: true,
        ),
      );
    }
  }

  void onWebViewDisposed(InAppWebViewController? controller) {
    if (identical(webController, controller)) {
      attach(null);
      session.noteWebViewUnmounted();
      session.clearAwaitingColdInitialNavigation();
      _navigation.cancelNudge();
      session.audibility.cancelPending();
      _bumpVerifyGeneration();
      session.pollLoop.stop();
      // Defer: notifying during StatefulElement.unmount locks the tree
      // (ValueListenableBuilder markNeedsBuild assertion).
      session.scheduleMountTickBump();
    }
  }

  Future<void> onPageFinished(
    InAppWebViewController controller,
    String? url,
  ) async {
    if (!isYoutubeWatchPageLoadStopUrl(url)) {
      if (url != null && !url.startsWith('about:')) {
        _logWebView.fine('youtube skip load_stop url=$url');
      }
      _navigation.scheduleNonWatchRecovery();
      return;
    }
    session.noteWatchPageLoaded();
    // Fresh document: its <video> starts muted, so the next `playing` event
    // re-arms the per-document volume restore (covers cold open AND the
    // post-ad page reload).
    session.noteWatchDocumentLoaded();
    onLogInitPhase('load_stop');
    if (!session.loggedFirstPlaying) {
      _stallWatchdog.onLoadStop(session.videoId);
      _navigation.schedulePlaybackNudge();
    } else {
      _stallWatchdog.cancel();
      _navigation.cancelNudge();
    }
    await injectYoutubeMobileWatchPage(InAppWebViewJsChannel(controller));
    session.pollLoop.scheduleKick();
  }

  Future<void> recoverStalledPlayback() async {
    await _navigation.recoverStalledPlayback(
      maxStallRecoveries: maxStallRecoveries,
      stallRecoveryCount: () => _stallRecoveryCount,
      setStallRecoveryCount: (c) => _stallRecoveryCount = c,
      prepareWatchReload: () => prepareWatchReload(
        resetFirstPlaying: false,
        resetStallRecovery: false,
      ),
      cancelStallWatchdog: _stallWatchdog.cancel,
    );
  }

  Future<void> loadCurrentVideoIfAttached() =>
      _navigation.loadCurrentVideoIfAttached();

  Future<void> exitNativeFullscreen(InAppWebViewController controller) async {
    if (_rejectingNativeFullscreen) return;
    _rejectingNativeFullscreen = true;
    try {
      await YoutubeWebViewBridge.forceInlinePlayback(
        InAppWebViewJsChannel(controller),
      );
    } catch (e, st) {
      _logWebView.fine('Failed to force inline playback', e, st);
    } finally {
      _rejectingNativeFullscreen = false;
    }
  }

  Future<void> onNativeFullscreenExit(InAppWebViewController controller) async {
    final channel = InAppWebViewJsChannel(controller);
    await YoutubeWebViewBridge.forceInlinePlayback(channel);
    if (session.playing && !session.playbackCompleted) {
      await YoutubeWebViewBridge.play(channel);
    }
  }

  void stopPolling() => session.pollLoop.stop();

  void _bumpVerifyGeneration() => _verifyGeneration++;
}
