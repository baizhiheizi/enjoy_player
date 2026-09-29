/// Gates child mounting on the shared WebView environment resolving.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:enjoy_player/core/webview/platform_webview_environment.dart';

/// Builds [placeholder] (or nothing) until [ensureAppWebViewEnvironment]
/// resolves, then hands the resolved environment (null on non-Windows or
/// creation failure) to [builder] so [InAppWebView] never mounts with a stale
/// null environment while Windows creation is still in flight.
class WebViewEnvironmentGate extends StatefulWidget {
  const WebViewEnvironmentGate({
    super.key,
    this.environmentFuture,
    this.placeholder,
    required this.builder,
  });

  /// Defaults to [ensureAppWebViewEnvironment]; tests may inject a
  /// controlled future. Resolved once per gate instance, never in [build].
  final Future<WebViewEnvironment?>? environmentFuture;

  /// Shown while the environment future is pending; defaults to nothing.
  final Widget? placeholder;

  final Widget Function(BuildContext context, WebViewEnvironment? environment)
  builder;

  @override
  State<WebViewEnvironmentGate> createState() => _WebViewEnvironmentGateState();
}

class _WebViewEnvironmentGateState extends State<WebViewEnvironmentGate> {
  late final Future<WebViewEnvironment?> _environmentFuture;

  @override
  void initState() {
    super.initState();
    _environmentFuture =
        widget.environmentFuture ?? ensureAppWebViewEnvironment();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewEnvironment?>(
      future: _environmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        return widget.builder(context, snapshot.data);
      },
    );
  }
}
