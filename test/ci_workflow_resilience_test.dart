import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _diskGuardPath = '.github/scripts/ensure_macos_disk_headroom.sh';
const _retryScriptPath = '.github/scripts/retry_command.sh';
const _gradlePrefetchPath = 'tool/prefetch_gradle_distribution.sh';
const _iosToolchainPath = '.github/scripts/ensure_ios_ci_toolchain.sh';
const _platformInstallerPath = '.github/scripts/install_apple_platform.sh';

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

    test('the headroom floor is sized against the build it guards', () {
      final script = _read(_diskGuardPath);
      expect(
        script,
        contains('APPLE_DISK_HEADROOM_GIB:-8'),
        reason:
            'the floor has to be twice the macOS Release build\'s ~4 GB peak '
            'DerivedData — high enough to catch the volume before the build '
            'reaches zero, low enough that the runner can reach it without '
            'manual cleanup',
      );
    });

    test('fails closed when the free space cannot be measured', () async {
      final sandbox = await Directory.systemTemp.createTemp('disk_guard_');
      addTearDown(() => sandbox.delete(recursive: true));
      final stubBin = Directory('${sandbox.path}/bin')
        ..createSync(recursive: true);
      // A `df` whose output has no capacity column: the free space cannot be
      // parsed, and the guard must refuse to start a build rather than
      // compare an empty value.
      File('${stubBin.path}/df').writeAsStringSync(r'''#!/bin/sh
printf 'Filesystem 1024-blocks Used Available\\n'
printf 'weird-device 100 50 50\\n'
exit 0
''');
      Process.runSync('chmod', ['+x', '${stubBin.path}/df']);

      final result = await Process.run(
        'bash',
        [_diskGuardPath, 'check'],
        environment: {
          'PATH': '${stubBin.path}:${Platform.environment['PATH']}',
          'APPLE_WORKSPACE_ROOT': sandbox.path,
          'APPLE_DISK_HEADROOM_GIB': '8',
          'RUNNER_TOOL_CACHE': '${sandbox.path}/tool',
        },
      );

      expect(
        result.exitCode,
        isNot(0),
        reason: 'an unmeasurable volume must not pass the guard',
      );
      expect(result.stdout.toString(), contains('Could not measure'));
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

    test('the Linux release build retries a command-level failure', () {
      final workflow = _read(_linuxWorkflowPath);
      expect(
        workflow,
        contains('retry_command.sh'),
        reason:
            'a command-level failure (the compile process killed, a flaky '
            'configure step) leaves the job alive, so the expensive release '
            'compile must be retried',
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

    test('the iOS toolchain check asks for the device platform', () {
      final script = _read(_iosToolchainPath);
      expect(
        script,
        contains(r'-architectureVariant "${variant}"'),
        reason: 'the platform request has to name the variant explicitly',
      );
      expect(
        script,
        contains('for variant in universal arm64'),
        reason:
            'the universal variant carries the device platform the generic '
            'iOS destination needs; the arm64 variant is only the simulator '
            'runtime, and asking for it alone reported "already present" on a '
            'runner that had no device platform',
      );
      expect(
        script,
        isNot(contains('for variant in arm64 universal')),
        reason: 'the device platform has to be requested first',
      );
      expect(
        script,
        contains('grep -qv "error:"'),
        reason:
            'the destination check has to reject an ineligible destination — '
            'the placeholder id also appears in the ineligible list',
      );
      expect(
        script,
        contains('run_with_timeout'),
        reason:
            'the platform download prints no progress, so it has to be '
            'bounded and retried instead of hanging the runner',
      );
    });

    test('the platform installer restores the firewall it changed', () {
      final script = _read(_platformInstallerPath);
      expect(File(_platformInstallerPath).existsSync(), isTrue);
      expect(
        script,
        contains('block out proto udp to port 443'),
        reason: 'the QUIC fallback is the whole point of the installer',
      );
      expect(
        script,
        contains('trap cleanup EXIT INT TERM'),
        reason:
            'the rule has to be removed even when the script is interrupted, '
            'or the host is left without QUIC',
      );
      expect(
        script,
        contains('pfctl -d'),
        reason:
            'macOS ships pf disabled; the installer has to restore that state '
            'rather than leave the host firewalled',
      );
      expect(
        script,
        contains(r'cp "${backup_file}" /etc/pf.conf'),
        reason: 'the anchor added to /etc/pf.conf has to be removed again',
      );
      expect(
        script,
        contains('--dry-run'),
        reason:
            'the ruleset has to be verifiable without enabling pf or editing '
            '/etc/pf.conf',
      );
    });

    test('the pf ruleset blocks UDP/443 last', () async {
      final result = await Process.run('bash', [
        _platformInstallerPath,
        '--print-ruleset',
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final lines = result.stdout
          .toString()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      expect(lines, isNotEmpty);
      expect(
        lines.last,
        'block out proto udp to port 443',
        reason:
            'pf is last-match-wins: a block that any later rule overrides '
            'never takes effect, so it has to be the last rule',
      );
      expect(
        lines.any((line) => line.startsWith('pass out all')),
        isTrue,
        reason:
            'the ruleset has to be self-contained — macOS\'s stock pf.conf '
            'has no top-level pass rule, so relying on the default policy '
            'would gamble with the host\'s connectivity',
      );
    });

    test('the iOS toolchain check rejects an ineligible destination', () async {
      final sandbox = await Directory.systemTemp.createTemp('ios_toolchain_');
      addTearDown(() => sandbox.delete(recursive: true));
      final stubBin = Directory('${sandbox.path}/bin')
        ..createSync(recursive: true);

      File('${stubBin.path}/xcodebuild').writeAsStringSync(r'''#!/bin/sh
case "$*" in
  *-showdestinations*)
    cat "$FIXTURE_DIR/destinations.txt"
    ;;
  *-downloadPlatform*)
    printf 'No needed downloadables found for %s\\n' "$(echo "$*" | sed -n 's/.*architectureVariant \\([^ ]*\\).*/\\1/p')"
    exit 1
    ;;
esac
exit 0
''');
      File('${stubBin.path}/killall').writeAsStringSync('#!/bin/sh\nexit 0\n');
      File('${stubBin.path}/xcrun').writeAsStringSync('#!/bin/sh\nexit 0\n');
      for (final stub in ['xcodebuild', 'killall', 'xcrun']) {
        Process.runSync('chmod', ['+x', '${stubBin.path}/$stub']);
      }

      Future<ProcessResult> runWithDestinations(String fixture) async {
        File('${sandbox.path}/destinations.txt').writeAsStringSync(fixture);
        return Process.run(
          'bash',
          [_iosToolchainPath],
          environment: {
            'PATH': '${stubBin.path}:${Platform.environment['PATH']}',
            'FIXTURE_DIR': sandbox.path,
          },
        );
      }

      const eligible = '''
Available destinations for the "Runner" scheme:
\t\t{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
''';
      const ineligible = '''
Ineligible destinations for the "Runner" scheme:
\t\t{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device, error:iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components. }
''';

      final eligibleResult = await runWithDestinations(eligible);
      expect(
        eligibleResult.exitCode,
        0,
        reason:
            'an eligible destination must pass:\n'
            '${eligibleResult.stdout}\n${eligibleResult.stderr}',
      );
      expect(eligibleResult.stdout.toString(), contains('is available'));

      final ineligibleResult = await runWithDestinations(ineligible);
      expect(
        ineligibleResult.exitCode,
        isNot(0),
        reason:
            'the placeholder id also appears in the ineligible list, so a '
            'check that only matches the id passes on exactly the runner it '
            'is meant to catch',
      );
      expect(
        '${ineligibleResult.stdout}${ineligibleResult.stderr}',
        contains('No usable generic'),
      );
    });

    test(
      'the Gradle prefetch replaces a truncated distribution archive',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'gradle_prefetch_',
        );
        addTearDown(() => sandbox.delete(recursive: true));

        final scriptDir = Directory('${sandbox.path}/tool')
          ..createSync(recursive: true);
        File(
          '${scriptDir.path}/prefetch_gradle_distribution.sh',
        ).writeAsStringSync(_read(_gradlePrefetchPath));
        final androidDir = Directory('${sandbox.path}/android')
          ..createSync(recursive: true);
        final wrapperDir = Directory('${androidDir.path}/gradle/wrapper')
          ..createSync(recursive: true);
        File('${wrapperDir.path}/gradle-wrapper.properties').writeAsStringSync(
          '''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-all.zip
''',
        );
        File('${wrapperDir.path}/gradle-wrapper.jar').writeAsStringSync('jar');

        // A wrapper that reports the distribution as missing until a valid
        // archive is in place, then succeeds.
        File('${androidDir.path}/gradlew').writeAsStringSync(r'''#!/bin/sh
archive="$GRADLE_USER_HOME/wrapper/dists/gradle-9.3.1-all/hash/gradle-9.3.1-all.zip"
if [ -f "$archive" ] && unzip -tqq "$archive" >/dev/null 2>&1; then
  exit 0
fi
exit 1
''');
        Process.runSync('chmod', ['+x', '${androidDir.path}/gradlew']);

        final stubBin = Directory('${sandbox.path}/bin')
          ..createSync(recursive: true);
        File('${stubBin.path}/curl').writeAsStringSync(r'''#!/bin/sh
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
mkdir -p "$(dirname "$out")"
cp "$FIXTURE_DIR/valid.zip" "$out"
exit 0
''');
        Process.runSync('chmod', ['+x', '${stubBin.path}/curl']);

        // A real (small) zip to serve as the download.
        final zipDir = Directory('${sandbox.path}/zip')
          ..createSync(recursive: true);
        File('${zipDir.path}/payload.txt').writeAsStringSync('gradle');
        Process.runSync('zip', [
          '-q',
          '-j',
          '${sandbox.path}/valid.zip',
          '${zipDir.path}/payload.txt',
        ]);

        final gradleHome = '${sandbox.path}/gradle-home';
        final distDir = Directory(
          '$gradleHome/wrapper/dists/gradle-9.3.1-all/hash',
        )..createSync(recursive: true);
        final archiveFile = File('${distDir.path}/gradle-9.3.1-all.zip');
        archiveFile.writeAsStringSync('PK not really a zip');

        final result = await Process.run(
          'bash',
          ['${scriptDir.path}/prefetch_gradle_distribution.sh'],
          environment: {
            'PATH': '${stubBin.path}:${Platform.environment['PATH']}',
            'FIXTURE_DIR': sandbox.path,
            'GRADLE_USER_HOME': gradleHome,
            'FLUTTER_ROOT': '${sandbox.path}/no-sdk',
          },
        );

        expect(
          result.exitCode,
          0,
          reason: 'prefetch failed:\n${result.stdout}\n${result.stderr}',
        );
        expect(
          archiveFile.existsSync(),
          isTrue,
          reason: 'the distribution archive has to be in place afterwards',
        );
        expect(archiveFile.readAsBytesSync().length, greaterThan(0));
        final unzipCheck = Process.runSync('unzip', ['-tqq', archiveFile.path]);
        expect(
          unzipCheck.exitCode,
          0,
          reason:
              'the truncated archive has to be replaced by one that actually '
              'unzips — that is the whole point of the prefetch',
        );
      },
    );
  });
}
