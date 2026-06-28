/// Writes a one-line session banner to the diagnostic log file.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:enjoy_player/core/webview/platform_webview_environment.dart';

Future<void> writeDiagnosticSessionHeader({String? localeTag}) async {
  final sink = LogFileSink.instance ?? await LogFileSink.ensureInitialized();
  if (sink == null) return;

  final info = await PackageInfo.fromPlatform();
  final channel = resolveDistributionChannel().name;
  final platform = Platform.operatingSystem;
  final mode = kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');
  final locale = localeTag ?? Platform.localeName;
  final verbose = DiagnosticLogConfig.verboseEnabled;
  final exe = Platform.resolvedExecutable;
  final webViewData = windowsWebViewUserDataFolder;

  await sink.writeRawLine(
    '[INFO] session: app=${info.version}+${info.buildNumber} '
    'platform=$platform mode=$mode channel=$channel locale=$locale '
    'diagnosticVerbose=$verbose exe=$exe'
    '${webViewData != null ? ' webViewUserData=$webViewData' : ''}',
  );
}
