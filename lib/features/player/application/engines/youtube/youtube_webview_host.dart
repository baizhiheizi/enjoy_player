/// Shared [InAppWebView] host for [YoutubePlayerEngine] (single instance per engine).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/webview/platform_webview_environment.dart';
import 'youtube_player_engine.dart';
import 'youtube_watch_navigation_policy.dart';
import 'youtube_webview_bridge.dart';

/// One [InAppWebView] per [YoutubePlayerEngine]; mounted in the video stage slot.
class YoutubeWebViewHost extends StatefulWidget {
  const YoutubeWebViewHost({required this.engine, super.key});

  final YoutubePlayerEngine engine;

  @override
  State<YoutubeWebViewHost> createState() => _YoutubeWebViewHostState();
}

class _YoutubeWebViewHostState extends State<YoutubeWebViewHost> {
  InAppWebViewController? _controller;

  @override
  void dispose() {
    widget.engine.onWebViewDisposed(_controller);
    super.dispose();
  }

  Future<NavigationActionPolicy> _onShouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url?.toString() ?? '';
    final videoId = widget.engine.currentVideoId;
    final allowed = shouldAllowYoutubeWatchNavigation(
      url: url,
      videoId: videoId,
      isForMainFrame: resolveYoutubeNavigationIsForMainFrame(
        action.isForMainFrame,
      ),
    );
    if (!allowed &&
        action.isForMainFrame &&
        url.contains('accounts.google.com') &&
        videoId.isNotEmpty) {
      unawaited(widget.engine.onSignInNavigationBlocked(controller));
    }
    return allowed
        ? NavigationActionPolicy.ALLOW
        : NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final vid = e.currentVideoId;
    final iosInlinePlayback = defaultTargetPlatform == TargetPlatform.iOS;

    final initialUrl = vid.isEmpty
        ? YoutubeWebViewBridge.idleUri
        : YoutubeWebViewBridge.watchUri(vid);

    return ExcludeSemantics(
      child: InAppWebView(
        webViewEnvironment: appWebViewEnvironment,
        initialSettings: YoutubeWebViewSettings.forPlayer(),
        onWebViewCreated: (controller) {
          _controller = controller;
          // [initialUrlRequest] already navigates on cold mount when [vid] is set;
          // avoid a second [loadWatchPage] that interrupts the first playback start.
          e.onWebViewCreated(
            controller,
            initialWatchUrlRequested: vid.isNotEmpty,
          );
        },
        onEnterFullscreen: iosInlinePlayback
            ? (controller) {
                unawaited(e.exitNativeFullscreen(controller));
              }
            : null,
        onExitFullscreen: iosInlinePlayback
            ? (controller) {
                unawaited(e.onNativeFullscreenExit(controller));
              }
            : null,
        onLoadStop: (controller, url) async {
          await e.onPageFinished(controller, url?.toString());
        },
        onReceivedHttpError: (controller, request, response) {
          e.onWebResourceHttpError(
            url: request.url.toString(),
            statusCode: response.statusCode,
            isForMainFrame: request.isForMainFrame ?? false,
          );
        },
        onReceivedError: (controller, request, error) {
          if (request.isForMainFrame != true) return;
          e.onWebResourceLoadError(
            url: request.url.toString(),
            description: error.description,
          );
        },
        onWebContentProcessDidTerminate: (controller) {
          unawaited(e.onWebViewProcessTerminated());
        },
        onRenderProcessGone: (controller, detail) {
          unawaited(e.onWebViewProcessTerminated());
        },
        shouldOverrideUrlLoading: _onShouldOverrideUrlLoading,
        initialUrlRequest: URLRequest(url: initialUrl),
      ),
    );
  }
}
