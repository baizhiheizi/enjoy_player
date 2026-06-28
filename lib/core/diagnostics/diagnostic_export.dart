/// Builds a diagnostic zip (rotated logs + manifest) for support export.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/core/release/distribution_channel.dart';

class DiagnosticExportManifest {
  const DiagnosticExportManifest({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.buildMode,
    required this.distributionChannel,
    required this.exportedAt,
    required this.diagnosticVerboseEnabled,
    this.locale,
  });

  final String appVersion;
  final String buildNumber;
  final String platform;
  final String buildMode;
  final String distributionChannel;
  final DateTime exportedAt;
  final bool diagnosticVerboseEnabled;
  final String? locale;

  Map<String, dynamic> toJson() => {
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'platform': platform,
    'buildMode': buildMode,
    'distributionChannel': distributionChannel,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'diagnosticVerboseEnabled': diagnosticVerboseEnabled,
    if (locale != null) 'locale': locale,
  };
}

/// Builds a zip archive from [manifest] and optional [logFileEntries].
Archive buildDiagnosticArchive({
  required DiagnosticExportManifest manifest,
  Iterable<MapEntry<String, List<int>>> logFileEntries = const [],
}) {
  final archive = Archive();
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  archive.addFile(
    ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
  );
  for (final entry in logFileEntries) {
    archive.addFile(
      ArchiveFile('logs/${entry.key}', entry.value.length, entry.value),
    );
  }
  return archive;
}

/// Creates zip bytes from current log files and [manifest].
Future<List<int>> buildDiagnosticExportZip({
  required DiagnosticExportManifest manifest,
}) async {
  final logEntries = <MapEntry<String, List<int>>>[];
  final sink = LogFileSink.instance ?? await LogFileSink.ensureInitialized();
  if (sink != null) {
    for (final file in sink.listLogFiles()) {
      if (!file.existsSync()) continue;
      final name = p.basename(file.path);
      logEntries.add(MapEntry(name, await file.readAsBytes()));
    }
  }
  return ZipEncoder().encode(
    buildDiagnosticArchive(manifest: manifest, logFileEntries: logEntries),
  );
}

DiagnosticExportManifest defaultExportManifest({
  required String appVersion,
  required String buildNumber,
  String? locale,
}) {
  final mode = kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');
  return DiagnosticExportManifest(
    appVersion: appVersion,
    buildNumber: buildNumber,
    platform: Platform.operatingSystem,
    buildMode: mode,
    distributionChannel: resolveDistributionChannel().name,
    exportedAt: DateTime.now().toUtc(),
    diagnosticVerboseEnabled: DiagnosticLogConfig.verboseEnabled,
    locale: locale,
  );
}
