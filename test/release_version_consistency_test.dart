import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final rawVersion = _rawPubspecVersion();
  final marketingVersion = rawVersion.split('+').first;
  final installerVersion = _installerVersion();

  test('the pubspec version carries a build number', () {
    expect(rawVersion, matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')));
  });

  test('the Windows installer version matches the pubspec version', () {
    expect(
      installerVersion,
      marketingVersion,
      reason:
          'windows/installer/enjoy_player.iss drifted from pubspec.yaml. '
          'Run bash .github/scripts/sync_release_version.sh.',
    );
  });

  test('the released version has release notes', () {
    final notesFile = File('docs/releases/$marketingVersion.md');
    final changelog = File('CHANGELOG.md').readAsStringSync();

    expect(
      notesFile.existsSync() || changelog.contains('## [$marketingVersion]'),
      isTrue,
      reason:
          'No release notes for $marketingVersion: neither '
          'docs/releases/$marketingVersion.md nor a "## [$marketingVersion]" '
          'CHANGELOG.md section exists. release_publish.yml publishes one of '
          'the two and fails when both are missing.',
    );
  });

  test('every version with release notes has a CHANGELOG section', () {
    final changelog = File('CHANGELOG.md').readAsStringSync();
    final notes =
        Directory('docs/releases')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.md'))
            .map((file) => file.uri.pathSegments.last.replaceAll('.md', ''))
            .toList()
          ..sort();

    final withoutSection = notes
        .where((version) => !changelog.contains('## [$version]'))
        .toList();

    expect(
      withoutSection,
      isEmpty,
      reason:
          'These versions have a docs/releases/<version>.md file but no '
          '"## [<version>]" CHANGELOG.md section, so the changelog loses '
          'their changes: ${withoutSection.join(', ')}.',
    );
  });
}

String _rawPubspecVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw StateError('pubspec.yaml has no version: line');
  }
  return match.group(1)!;
}

String? _installerVersion() {
  final installer = File(
    'windows/installer/enjoy_player.iss',
  ).readAsStringSync();
  final match = RegExp(r'#define MyAppVersion "([^"]+)"').firstMatch(installer);
  return match?.group(1);
}
