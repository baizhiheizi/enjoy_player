/// Cross-platform entry for shared in-app WebView environment settings.
library;

export 'windows_webview_environment.dart'
    show
        ensureWindowsWebViewEnvironment,
        windowsWebViewEnvironment,
        windowsWebViewUserDataFolder;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'windows_webview_environment.dart';

/// [WebViewEnvironment] passed to every [InAppWebView] (Windows WebView2 only).
WebViewEnvironment? get appWebViewEnvironment => windowsWebViewEnvironment;
