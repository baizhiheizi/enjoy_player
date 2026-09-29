/// Shared WebView2 environment with a writable user-data folder on Windows.
///
/// When [userDataFolder] is omitted, WebView2 defaults to a directory next to the
/// executable (`{exe}.WebView2`). That fails under `Program Files` (Inno Setup
/// installs), which breaks YouTube playback while portable builds still work.
library;

import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('WebViewEnvironment');

Future<WebViewEnvironment?>? _windowsEnvironmentFuture;
final Future<WebViewEnvironment?> _unsupportedPlatformEnvironment =
    Future<WebViewEnvironment?>.value(null);
WebViewEnvironment? _windowsEnvironment;
String? _windowsUserDataFolder;

/// Resolved user-data path when environment creation succeeded.
String? get windowsWebViewUserDataFolder => _windowsUserDataFolder;

/// Starts (once per process) or joins the shared environment creation.
///
/// Returns the created environment, or null on other platforms / init
/// failure — callers must fall back to the plugin's default environment,
/// exactly as they would without this call.
Future<WebViewEnvironment?> ensureWindowsWebViewEnvironment() {
  if (!Platform.isWindows) return _unsupportedPlatformEnvironment;
  return _windowsEnvironmentFuture ??= _createWindowsWebViewEnvironment();
}

Future<WebViewEnvironment?> _createWindowsWebViewEnvironment() async {
  try {
    final support = await getApplicationSupportDirectory();
    final folder = p.join(support.path, 'WebView2');
    await Directory(folder).create(recursive: true);
    _windowsUserDataFolder = folder;
    _windowsEnvironment = await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(userDataFolder: folder),
    );
    _log.info('WebView2 environment ready userDataFolder=$folder');
    return _windowsEnvironment;
  } on Object catch (e, st) {
    _log.warning('WebView2 environment creation failed', e, st);
    return null;
  }
}
