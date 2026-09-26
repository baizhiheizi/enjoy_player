/// App-owned seam over the YouTube watch-page JS channel (issue #767).
///
/// The engine cluster speaks this interface, not the plugin's controller:
/// production runs on [InAppWebViewJsChannel]; tests run on a scripted
/// adapter that records evaluated sources and plays back queued results —
/// the "tier 2 runtime harness" `youtube_js_protocol_contract_test.dart`
/// anticipates. Two adapters make the seam real: protocol scripts and decode
/// can be *executed* against a fake instead of regexed out of source.
///
/// The inbound half of the protocol (page → Dart `callHandler` messages) is
/// already app-owned — `YoutubeWebViewController` registers the handlers and
/// forwards to `YoutubeWebViewEvents.handle`, a plain Dart function.
library;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract interface class YoutubeJsChannel {
  /// Evaluates [source] in the watch page; returns the script's JS value
  /// (or null when it evaluates to undefined / returns nothing).
  Future<Object?> evaluate(String source);

  /// Navigates the WebView to [uri].
  Future<void> loadUri(Uri uri);
}

/// Production adapter over the plugin's controller.
final class InAppWebViewJsChannel implements YoutubeJsChannel {
  const InAppWebViewJsChannel(this._controller);

  final InAppWebViewController _controller;

  @override
  Future<Object?> evaluate(String source) =>
      _controller.evaluateJavascript(source: source);

  @override
  Future<void> loadUri(Uri uri) async {
    await _controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(uri.toString())),
    );
  }
}
