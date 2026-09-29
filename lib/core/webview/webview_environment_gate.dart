/// Gates child mounting on the shared WebView environment resolving.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/webview/platform_webview_environment.dart';

/// Builds nothing until [ensureAppWebViewEnvironment] resolves, then hands
/// the resolved environment (null on non-Windows or creation failure) to
/// [builder] so [InAppWebView] never mounts with a stale null environment
/// while Windows creation is still in flight.
class WebViewEnvironmentGate extends StatelessWidget {
  const WebViewEnvironmentGate({
    super.key,
    this.environmentFuture,
    required this.builder,
  });

  /// Defaults to [ensureAppWebViewEnvironment]; tests may inject a
  /// controlled future.
  final Future<WebViewEnvironment?>? environmentFuture;

  final Widget Function(BuildContext context, WebViewEnvironment? environment)
  builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewEnvironment?>(
      future: environmentFuture ?? ensureAppWebViewEnvironment(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return builder(context, snapshot.data);
      },
    );
  }
}
