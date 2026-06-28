import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kProfileMode, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/logging/diagnostic_log_config.dart';
import 'core/logging/diagnostic_session_header.dart';
import 'core/logging/log.dart';
import 'core/logging/setup_logging.dart';
import 'core/webview/platform_webview_environment.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(_bootstrap, _onZoneError);
}

final Logger _bootstrapLog = logNamed('bootstrap');

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Two AppDatabase instances are expected: the device-global `guest` DB
  // (settings such as API base URL) and the per-user signed-in DB. They use
  // separate files and separate isolate executors, so Drift's runtime check
  // for "multiple databases" is a false positive here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await DiagnosticLogConfig.loadFromGuestSettings();
  await setupAppLogging();
  _installFrameworkErrorHandlers();
  if (defaultTargetPlatform == TargetPlatform.windows) {
    await ensureWindowsWebViewEnvironment();
  }
  try {
    await writeDiagnosticSessionHeader();
  } on Object catch (e, st) {
    _bootstrapLog.warning('writeDiagnosticSessionHeader failed', e, st);
  }
  MediaKit.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(880, 560));
    await windowManager.waitUntilReadyToShow(const WindowOptions(), () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  const root = ProviderScope(child: EnjoyApp());
  Widget app = root;
  // Windows AXTree sync bug (flutter/flutter#182444): semantics churn from
  // ListView/Tooltip/etc. floods the console. Per-WebView ExcludeSemantics
  // alone is not enough; skip semantics in debug/profile on Windows only.
  if (defaultTargetPlatform == TargetPlatform.windows &&
      (kDebugMode || kProfileMode)) {
    app = const ExcludeSemantics(child: root);
  }
  runApp(app);
}

void _installFrameworkErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    _bootstrapLog.severe(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _bootstrapLog.severe('PlatformDispatcher error', error, stack);
    return true;
  };
}

void _onZoneError(Object error, StackTrace stack) {
  _bootstrapLog.severe('Uncaught zone error', error, stack);
}
