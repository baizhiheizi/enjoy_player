import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _diskGuardPath = '.github/scripts/ensure_macos_disk_headroom.sh';
const _retryScriptPath = '.github/scripts/retry_command.sh';
const _gradlePrefetchPath = 'tool/prefetch_gradle_distribution.sh';

const _appleWorkflowPath = '.github/workflows/build_apple.yml';
const _releaseAppleWorkflowPath = '.github/workflows/release_apple.yml';
const _linuxWorkflowPath = '.github/workflows/build_linux.yml';
const _windowsWorkflowPath = '.github/workflows/build_windows.yml';
const _apkWorkflowPath = '.github/workflows/android_apk_smoke.yml';
const _releaseAndroidWorkflowPath = '.github/workflows/release_android.yml';

String _read(String path) => File(path).readAsStringSync();

Future<ProcessResult> _runScript(
  String path,
  List<String> args, {
  Map<String, String>? environment,
}) {
  return Process.run('bash', [path, ...args], environment: environment);
}

void main() {
  group('ensure_macos_disk_headroom.sh', () {
    late Directory scratch;
    late Directory toolCache;

    setUp(() async {
      scratch = await Directory.systemTemp.createTemp('apple_disk_guard_');
      toolCache = await Directory.systemTemp.createTemp('apple_tool_cache_');
    });

    tearDown(() async {
      await scratch.delete(recursive: true);
      await toolCache.delete(recursive: true);
    });

    test('rejects a volume that cannot hold the Apple build', () async {
      final result = await _runScript(
        _diskGuardPath,
        ['check'],
        environment: {
          'APPLE_DISK_HEADROOM_GIB': '1000000',
          'APPLE_WORKSPACE_ROOT': scratch.path,
          'RUNNER_TOOL_CACHE': toolCache.path,
        },
      );

      expect(result.exitCode, isNot(0));
      expect(result.stdout.toString(), contains('::error::'));
    });

    test('accepts a volume with enough headroom', () async {
      final result = await _runScript(
        _diskGuardPath,
        ['check'],
        environment: {
          'APPLE_DISK_HEADROOM_GIB': '1',
          'APPLE_WORKSPACE_ROOT': scratch.path,
          'RUNNER_TOOL_CACHE': toolCache.path,
        },
      );

      expect(result.exitCode, 0, reason: result.stdout.toString());
    });

    test(
      'prune drops the superseded Flutter SDK and keeps the pinned one',
      () async {
        final pinned = RegExp(
          r'^flutter\s*=\s*"([^"]+)"',
          multiLine: true,
        ).firstMatch(_read('mise.toml'))!.group(1)!;
        final superseded = Directory('${toolCache.path}/flutter-0.0.1-stable')
          ..createSync(recursive: true);
        final current = Directory('${toolCache.path}/flutter-$pinned-stable')
          ..createSync(recursive: true);
        final ios = Directory('${scratch.path}/build/ios')
          ..createSync(recursive: true);
        final macos = Directory('${scratch.path}/build/macos')
          ..createSync(recursive: true);

        final result = await _runScript(
          _diskGuardPath,
          ['prune'],
          environment: {
            'APPLE_DISK_HEADROOM_GIB': '1',
            'APPLE_WORKSPACE_ROOT': scratch.path,
            'RUNNER_TOOL_CACHE': toolCache.path,
          },
        );

        expect(result.exitCode, 0, reason: result.stdout.toString());
        expect(superseded.existsSync(), isFalse);
        expect(current.existsSync(), isTrue);
        expect(ios.existsSync(), isFalse);
        expect(macos.existsSync(), isFalse);
      },
    );

    test('check mode never deletes anything', () async {
      final kept = Directory('${toolCache.path}/flutter-0.0.1-stable')
        ..createSync(recursive: true);
      final ios = Directory('${scratch.path}/build/ios')
        ..createSync(recursive: true);

      final result = await _runScript(
        _diskGuardPath,
        ['check'],
        environment: {
          'APPLE_DISK_HEADROOM_GIB': '1',
          'APPLE_WORKSPACE_ROOT': scratch.path,
          'RUNNER_TOOL_CACHE': toolCache.path,
        },
      );

      expect(result.exitCode, 0, reason: result.stdout.toString());
      expect(kept.existsSync(), isTrue);
      expect(ios.existsSync(), isTrue);
    });

    test('rejects an unknown mode', () async {
      final result = await _runScript(_diskGuardPath, ['nonsense']);
      expect(result.exitCode, 2);
    });
  });

  group('retry_command.sh', () {
    test('retries until the command succeeds', () async {
      final dir = await Directory.systemTemp.createTemp('retry_command_');
      addTearDown(() => dir.delete(recursive: true));
      final marker = File('${dir.path}/attempts');
      final helper = File('${dir.path}/attempt.sh')
        ..writeAsStringSync(r'''
#!/usr/bin/env bash
count=0
[ -f "$1" ] && count=$(cat "$1")
count=$((count + 1))
echo "$count" > "$1"
[ "$count" -ge 3 ] || exit 1
exit 0
''');
      Process.runSync('chmod', ['+x', helper.path]);

      final result = await _runScript(_retryScriptPath, [
        '5',
        '0',
        helper.path,
        marker.path,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(marker.readAsStringSync().trim(), '3');
    });

    test('gives up and propagates the last exit status', () async {
      final result = await _runScript(_retryScriptPath, [
        '2',
        '0',
        'bash',
        '-c',
        'exit 7',
      ]);

      expect(result.exitCode, 7);
    });

    test('rejects a missing command', () async {
      final result = await _runScript(_retryScriptPath, ['2', '0']);
      expect(result.exitCode, 2);
    });
  });

  group('workflow wiring', () {
    test('the Apple workflows check disk headroom before they build', () {
      for (final path in [_appleWorkflowPath, _releaseAppleWorkflowPath]) {
        final workflow = _read(path);
        final guardIndex = workflow.indexOf('ensure_macos_disk_headroom.sh');
        expect(
          guardIndex,
          greaterThanOrEqualTo(0),
          reason: '$path must claim the disk headroom before building',
        );
        final buildIndex = path == _releaseAppleWorkflowPath
            ? workflow.indexOf('release_apple.sh')
            : workflow.indexOf('build_macos_ci.sh');
        expect(
          guardIndex,
          lessThan(buildIndex),
          reason: '$path must claim the disk headroom before the build starts',
        );
      }
    });

    test('the Apple smoke jobs re-check before the release build', () {
      final workflow = _read(_appleWorkflowPath);
      expect(workflow, contains('ensure_macos_disk_headroom.sh check'));
      expect(
        workflow.indexOf('ensure_macos_disk_headroom.sh check'),
        lessThan(workflow.indexOf('build_macos_ci.sh Release')),
      );
      expect(
        workflow.indexOf('ensure_macos_disk_headroom.sh check'),
        lessThan(workflow.indexOf('build_ios_ci.sh Release')),
      );
    });

    test('every self-hosted platform job is bounded by a timeout', () {
      for (final path in [
        _appleWorkflowPath,
        _linuxWorkflowPath,
        _windowsWorkflowPath,
      ]) {
        final workflow = _read(path);
        expect(
          workflow,
          contains('timeout-minutes:'),
          reason:
              '$path runs on a self-hosted runner, where a job without a '
              'timeout can hold the runner forever',
        );
      }
    });

    test('the Linux release build retries a starved host', () {
      final workflow = _read(_linuxWorkflowPath);
      expect(
        workflow,
        contains('retry_command.sh'),
        reason:
            'ADR-0105 records the pool\'s "lost communication" shape as host '
            'starvation, so the expensive release compile must be retried',
      );
      expect(
        workflow.indexOf('retry_command.sh'),
        lessThan(workflow.indexOf('Upload debug bundle')),
      );
    });

    test('the Android workflows prefetch the Gradle distribution', () {
      for (final path in [_apkWorkflowPath, _releaseAndroidWorkflowPath]) {
        final workflow = _read(path);
        expect(
          workflow,
          contains('prefetch_gradle_distribution.sh'),
          reason:
              '$path must not depend on the Gradle wrapper\'s no-retry, '
              'no-integrity-check download',
        );
      }
      expect(File(_gradlePrefetchPath).existsSync(), isTrue);
    });
  });
}
