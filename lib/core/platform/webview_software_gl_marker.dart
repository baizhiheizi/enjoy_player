/// Cross-launch persistence for the Linux webview software-GL recovery
/// ([ADR-0096]).
///
/// `LIBGL_ALWAYS_SOFTWARE` is consulted by Mesa only at GL context creation,
/// so arming it inside a running app cannot repair the WPE hardware frame
/// export stall — the WebKit UI-side resources predate the flag. The Linux
/// runner reads this marker file before engine init and sets the flag for
/// the whole process tree instead.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('WebViewSoftwareGl');

/// Marker file the Linux runner checks in
/// `{XDG_DATA_HOME}/ai.enjoy.player.enjoy_player/`.
const softwareGlMarkerFileName = 'webview_software_gl';

/// Persists the marker so the next launch starts on software GL. Idempotent;
/// returns false on IO failure (manual `LIBGL_ALWAYS_SOFTWARE=1` remains the
/// fallback).
Future<bool> markSoftwareGlForNextLaunch({Directory? supportDirectory}) async {
  try {
    final dir = supportDirectory ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final marker = File(p.join(dir.path, softwareGlMarkerFileName));
    if (!marker.existsSync()) {
      await marker.create();
    }
    return true;
  } on Object catch (e, st) {
    _log.warning('failed to persist software GL marker for next launch', e, st);
    return false;
  }
}
