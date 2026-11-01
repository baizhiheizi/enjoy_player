import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _scriptPath = '.github/scripts/release_finalize.sh';
const _tag = 'v9.9.9';
const _version = '9.9.9';

const _windowsInstaller = 'EnjoyPlayerSetup-v$_version.exe';
const _macosZip = 'EnjoyPlayer-macOS-v$_version.zip';
const _linuxAppImage = 'enjoy-player-$_version-x86_64.AppImage';
const _androidAab = 'EnjoyPlayer-v$_version.aab';

const _ghStub = r'''
#!/bin/sh
if [ "$1" = "release" ] && [ "$2" = "view" ]; then
  for arg in "$@"; do
    if [ "$arg" = "--json" ]; then
      printf '%s' "$GH_STUB_ASSETS"
      exit 0
    fi
  done
  if [ "$GH_STUB_MISSING" = "true" ]; then
    exit 1
  fi
  exit 0
fi
if [ "$1" = "release" ] && [ "$2" = "edit" ]; then
  printf '%s\n' "$*" >> "$GH_STUB_LOG"
  exit 0
fi
exit 1
''';

void main() {
  final skipOnWindows = Platform.isWindows
      ? 'The release gate harness needs a POSIX shell.'
      : false;

  late Directory sandbox;
  late String ghLog;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('release_finalize_test');
    final bin = Directory(p.join(sandbox.path, 'bin'))
      ..createSync(recursive: true);
    final stub = File(p.join(bin.path, 'gh'))..writeAsStringSync(_ghStub);
    Process.runSync('chmod', ['+x', stub.path]);
    ghLog = p.join(sandbox.path, 'gh.log');
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  ProcessResult runGate(List<String> args, List<String> assets) {
    return Process.runSync(
      'bash',
      [_scriptPath, '--tag', _tag, ...args],
      environment: {
        'PATH':
            '${p.join(sandbox.path, 'bin')}:${Platform.environment['PATH']}',
        'GH_STUB_ASSETS': '${assets.join('\n')}\n',
        'GH_STUB_LOG': ghLog,
      },
      workingDirectory: Directory.current.path,
    );
  }

  List<String> promoteCalls() {
    final log = File(ghLog);
    if (!log.existsSync()) {
      return const [];
    }
    return log.readAsLinesSync();
  }

  test('publishes a release that carries every expected platform asset', () {
    final result = runGate(const [], [
      _windowsInstaller,
      _macosZip,
      _linuxAppImage,
      _androidAab,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(promoteCalls(), contains('release edit $_tag --draft=false'));
  }, skip: skipOnWindows);

  test('refuses to publish a release that is missing a platform asset', () {
    final result = runGate(const [], [_macosZip, _linuxAppImage, _androidAab]);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains(_windowsInstaller));
    expect(promoteCalls(), isEmpty);
  }, skip: skipOnWindows);

  test('names every missing platform asset', () {
    final result = runGate(const [], [_macosZip]);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains(_windowsInstaller));
    expect(result.stderr, contains(_linuxAppImage));
    expect(result.stderr, contains(_androidAab));
    expect(result.stderr, isNot(contains(_macosZip)));
  }, skip: skipOnWindows);

  test('publishes nothing in --check-only mode', () {
    final result = runGate(
      const ['--check-only'],
      [_windowsInstaller, _macosZip, _linuxAppImage, _androidAab],
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(promoteCalls(), isEmpty);
  }, skip: skipOnWindows);

  test('accepts an intentionally skipped channel', () {
    final result = runGate(
      ['--allow-missing', _androidAab],
      [_windowsInstaller, _macosZip, _linuxAppImage],
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(promoteCalls(), contains('release edit $_tag --draft=false'));
  }, skip: skipOnWindows);

  test('requires an extra asset when one is asked for', () {
    final result = runGate(
      ['--require', 'EnjoyPlayer-v$_version.ipa'],
      [_windowsInstaller, _macosZip, _linuxAppImage, _androidAab],
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('EnjoyPlayer-v$_version.ipa'));
    expect(promoteCalls(), isEmpty);
  }, skip: skipOnWindows);

  test('fails when the release does not exist', () {
    final result = Process.runSync(
      'bash',
      [_scriptPath, '--tag', 'v0.0.0-missing'],
      environment: {
        'PATH':
            '${p.join(sandbox.path, 'bin')}:${Platform.environment['PATH']}',
        'GH_STUB_ASSETS': '',
        'GH_STUB_LOG': ghLog,
        'GH_STUB_MISSING': 'true',
      },
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, isNot(0));
    expect(promoteCalls(), isEmpty);
  }, skip: skipOnWindows);
}
