import 'dart:convert';

import 'package:enjoy_player/core/diagnostics/diagnostic_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticExportManifest', () {
    test('serializes expected fields', () {
      final manifest = DiagnosticExportManifest(
        appVersion: '0.2.1',
        buildNumber: '2',
        platform: 'windows',
        buildMode: 'release',
        distributionChannel: 'direct',
        exportedAt: DateTime.utc(2026, 6, 22, 12, 0),
        diagnosticVerboseEnabled: true,
        locale: 'en-US',
      );

      final json = manifest.toJson();
      expect(json['appVersion'], '0.2.1');
      expect(json['buildNumber'], '2');
      expect(json['platform'], 'windows');
      expect(json['buildMode'], 'release');
      expect(json['distributionChannel'], 'direct');
      expect(json['diagnosticVerboseEnabled'], isTrue);
      expect(json['locale'], 'en-US');
      expect(json['exportedAt'], '2026-06-22T12:00:00.000Z');
    });
  });

  group('buildDiagnosticArchive', () {
    test('includes manifest and rotated log files', () {
      final manifest = DiagnosticExportManifest(
        appVersion: '0.2.1',
        buildNumber: '2',
        platform: 'windows',
        buildMode: 'release',
        distributionChannel: 'direct',
        exportedAt: DateTime.utc(2026, 6, 22),
        diagnosticVerboseEnabled: false,
      );

      final archive = buildDiagnosticArchive(
        manifest: manifest,
        logFileEntries: [
          MapEntry('enjoy-player.log', utf8.encode('line1\n')),
          MapEntry('enjoy-player.log.1', utf8.encode('line2\n')),
        ],
      );

      expect(archive.files.map((f) => f.name), [
        'manifest.json',
        'logs/enjoy-player.log',
        'logs/enjoy-player.log.1',
      ]);

      final manifestFile = archive.files.firstWhere(
        (f) => f.name == 'manifest.json',
      );
      final decoded =
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
      expect(decoded['appVersion'], '0.2.1');
    });
  });
}
