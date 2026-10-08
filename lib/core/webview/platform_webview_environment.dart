/// Cross-platform entry for shared in-app WebView environment settings.
library;

import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'linux_webview_environment.dart';
import 'windows_webview_environment.dart';

export 'linux_webview_environment.dart' show ensureLinuxWebViewEnvironment;
export 'windows_webview_environment.dart'
    show ensureWindowsWebViewEnvironment, windowsWebViewUserDataFolder;

final Future<WebViewEnvironment?> _unsupportedPlatformEnvironment =
    Future<WebViewEnvironment?>.value(null);

/// Resolves the shared WebView environment every [InAppWebView] must use.
///
/// Windows creates one shared WebView2 environment and Linux one shared
/// WPE WebKit environment (each cached per process — a failure is final for
/// the session and resolves to null); other platforms resolve synchronously
/// to a cached null future so repeated callers always receive the same
/// instance.
Future<WebViewEnvironment?> ensureAppWebViewEnvironment() {
  if (Platform.isWindows) return ensureWindowsWebViewEnvironment();
  if (Platform.isLinux) return ensureLinuxWebViewEnvironment();
  return _unsupportedPlatformEnvironment;
}
