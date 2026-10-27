import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Covers `macos/scripts/smoke_test_launch.sh`, the release-time guard against
/// a macOS bundle that dyld cannot load.
const _scriptPath = 'macos/scripts/smoke_test_launch.sh';

class _FakeApp {
  _FakeApp(this.root);

  final Directory root;

  late final Directory app;

  static _FakeApp create() {
    final root = Directory.systemTemp.createTempSync('macos_launch_smoke_');
    final fake = _FakeApp(root);
    fake.app = Directory('${root.path}/Enjoy Player.app')
      ..createSync(recursive: true);
    Directory('${fake.app.path}/Contents/MacOS').createSync(recursive: true);
    return fake;
  }

  void writeExecutable(String body) {
    final file = File('${app.path}/Contents/MacOS/Enjoy Player');
    file.writeAsStringSync(body);
    Process.runSync('chmod', ['+x', file.path]);
  }

  void writeBinaryExecutable(List<int> bytes) {
    final file = File('${app.path}/Contents/MacOS/Enjoy Player');
    file.writeAsBytesSync(bytes);
    Process.runSync('chmod', ['+x', file.path]);
  }

  ProcessResult run({int timeoutSeconds = 3}) {
    return Process.runSync(
      'bash',
      [_scriptPath, app.path],
      environment: {
        'PATH': Platform.environment['PATH'] ?? '',
        'MACOS_LAUNCH_SMOKE_TIMEOUT': '$timeoutSeconds',
      },
    );
  }

  void dispose() {
    root.deleteSync(recursive: true);
  }
}

void main() {
  final skipOnWindows = Platform.isWindows
      ? 'The smoke test harness needs a POSIX shell.'
      : false;

  test('passes when the app exits on its own without a loader failure', () {
    final fake = _FakeApp.create();
    addTearDown(fake.dispose);

    fake.writeExecutable('#!/bin/sh\nexit 0\n');

    final result = fake.run();

    expect(result.exitCode, 0, reason: result.stdout);
    expect(result.stdout, contains('no dynamic-linker failure'));
  }, skip: skipOnWindows);

  test('fails when the app dies with a dynamic-linker failure', () {
    final fake = _FakeApp.create();
    addTearDown(fake.dispose);

    fake.writeExecutable(
      '#!/bin/sh\n'
      'echo "dyld[123]: Library not loaded: @rpath/libbrotlicommon.1.dylib" >&2\n'
      'exit 134\n',
    );

    final result = fake.run();

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('dynamic-linker failure'));
    expect(result.stderr, contains('libbrotlicommon.1.dylib'));
  }, skip: skipOnWindows);

  test('fails when the executable cannot be launched at all', () {
    final fake = _FakeApp.create();
    addTearDown(fake.dispose);

    fake.writeBinaryExecutable([0, 1, 2, 3, 4, 5, 6, 7]);

    final result = fake.run();

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('never ran'));
  }, skip: skipOnWindows);

  test('passes when the app stays up for the whole timeout', () {
    final fake = _FakeApp.create();
    addTearDown(fake.dispose);

    fake.writeExecutable('#!/bin/sh\nsleep 30\n');

    final result = fake.run(timeoutSeconds: 2);

    expect(result.exitCode, 0, reason: result.stdout);
    expect(result.stdout, contains('stayed up'));
  }, skip: skipOnWindows);
}
