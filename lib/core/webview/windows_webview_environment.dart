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

WebViewEnvironment? _windowsEnvironment;
String? _windowsUserDataFolder;

/// Active Windows WebView2 environment, or null on other platforms / init failure.
WebViewEnvironment? get windowsWebViewEnvironment => _windowsEnvironment;

/// Resolved user-data path when [ensureWindowsWebViewEnvironment] succeeded.
String? get windowsWebViewUserDataFolder => _windowsUserDataFolder;

/// Creates one shared environment before any [InAppWebView] is mounted.
Future<WebViewEnvironment?> ensureWindowsWebViewEnvironment() async {
  if (!Platform.isWindows) return null;
  if (_windowsEnvironment != null) return _windowsEnvironment;

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
