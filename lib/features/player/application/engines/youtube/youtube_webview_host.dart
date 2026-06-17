/// Shared [InAppWebView] host for [YoutubePlayerEngine] (single instance per engine).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'youtube_player_engine.dart';
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

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final vid = e.currentVideoId;
    final iosInlinePlayback = defaultTargetPlatform == TargetPlatform.iOS;

    final initialUrl = vid.isEmpty
        ? YoutubeWebViewBridge.idleUri
        : YoutubeWebViewBridge.watchUri(vid);

    return InAppWebView(
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
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url?.toString() ?? '';
        if (url == 'about:blank' || url.startsWith('about:')) {
          return NavigationActionPolicy.ALLOW;
        }
        if (vid.isNotEmpty &&
            (url.contains('v=$vid') || url.contains('/$vid'))) {
          return NavigationActionPolicy.ALLOW;
        }
        if (url.contains('consent.youtube.com') ||
            url.contains('accounts.google.com') ||
            url.contains('myaccount.google.com') ||
            url.contains('gstatic.com') ||
            url.contains('googleapis.com')) {
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.CANCEL;
      },
      initialUrlRequest: URLRequest(url: initialUrl),
    );
  }
}
