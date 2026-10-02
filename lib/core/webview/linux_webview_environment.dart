/// Shared WPE WebKit environment with a writable user-data folder on Linux.
///
/// Mirrors [windows_webview_environment.dart]: without an explicit data
/// folder the plugin falls back to a default location that may not be
/// writable inside self-contained artifacts (AppImage), so YouTube playback
/// loses cookies and sessions across runs.
library;

import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('WebViewEnvironment');

Future<WebViewEnvironment?>? _linuxEnvironmentFuture;
final Future<WebViewEnvironment?> _unsupportedPlatformEnvironment =
    Future<WebViewEnvironment?>.value(null);

/// Starts (once per process) or joins the shared environment creation.
///
/// Returns the created environment, or null on other platforms / init
/// failure — callers must fall back to the plugin's default environment,
/// exactly as they would without this call.
Future<WebViewEnvironment?> ensureLinuxWebViewEnvironment() {
  if (!Platform.isLinux) return _unsupportedPlatformEnvironment;
  return _linuxEnvironmentFuture ??= _createLinuxWebViewEnvironment();
}

Future<WebViewEnvironment?> _createLinuxWebViewEnvironment() async {
  try {
    final support = await getApplicationSupportDirectory();
    final folder = p.join(support.path, 'WPEWebView');
    await Directory(folder).create(recursive: true);
    final environment = await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(userDataFolder: folder),
    );
    _log.info('WPE WebView environment ready userDataFolder=$folder');
    return environment;
  } on Object catch (e, st) {
    _log.warning('WPE WebView environment creation failed', e, st);
    return null;
  }
}
