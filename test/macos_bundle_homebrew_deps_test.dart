import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Drives `macos/scripts/bundle_ffmpeg_homebrew_deps.sh` with stand-ins for the
/// macOS-only tools it shells out to, so the bundler's dependency walk is
/// covered on every platform that runs the Dart test suite.
///
/// See `docs/packaging.md` (macOS) and issue #1096.
const _scriptPath = 'macos/scripts/bundle_ffmpeg_homebrew_deps.sh';

/// A dylib version no real Homebrew keg ships. The fixture load commands keep
/// the real `/opt/homebrew/opt/<formula>/lib/...` shape the bundler matches on,
/// so a machine that really has the formula installed (every macOS build host)
/// must not satisfy them: resolution has to go through the stubbed `brew`.
const _sandboxKegVersion = '99';
const _freetypeKegDylib = 'libfreetype.$_sandboxKegVersion.dylib';
const _brotlidecKegDylib = 'libbrotlidec.$_sandboxKegVersion.dylib';
const _brotlicommonKegDylib = 'libbrotlicommon.$_sandboxKegVersion.dylib';

const _otoolStub = r'''
#!/bin/sh
mode="$1"
shift
target="$1"
base=$(basename "$target")
case "$mode" in
  -L)
    deps="$FIXTURE_DIR/deps/$base"
    [ -f "$deps" ] || exit 0
    printf '%s:\n' "$target"
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      printf '\t%s (compatibility version 1.0.0, current version 1.0.0)\n' "$line"
    done <"$deps"
    ;;
  -l)
    printf '%s:\n' "$target"
    for source in "$FIXTURE_DIR/rpaths/$base" "$STATE_DIR/rpaths/$base"; do
      [ -f "$source" ] || continue
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf 'Load command 1\n          cmd LC_RPATH\n      cmdsize 48\n         path %s (offset 12)\n' "$line"
      done <"$source"
    done
    ;;
esac
exit 0
''';

const _installNameToolStub = r'''
#!/bin/sh
mode="$1"
case "$mode" in
  -id)
    name="$2"
    target="$3"
    ;;
  -change)
    old="$2"
    new="$3"
    target="$4"
    ;;
  -add_rpath)
    rp="$2"
    target="$3"
    ;;
  *)
    exit 0
    ;;
esac
base=$(basename "$target")
mkdir -p "$STATE_DIR/ids" "$STATE_DIR/rpaths" "$STATE_DIR/changes"
case "$mode" in
  -id)
    printf '%s\n' "$name" >"$STATE_DIR/ids/$base"
    ;;
  -change)
    printf '%s\t%s\n' "$old" "$new" >>"$STATE_DIR/changes/$base"
    deps="$FIXTURE_DIR/deps/$base"
    if [ -f "$deps" ]; then
      awk -v old="$old" -v new="$new" '{ if ($0 == old) print new; else print }' "$deps" >"$deps.tmp"
      mv "$deps.tmp" "$deps"
    fi
    ;;
  -add_rpath)
    printf '%s\n' "$rp" >>"$STATE_DIR/rpaths/$base"
    ;;
esac
exit 0
''';

const _fileStub = r'''
#!/bin/sh
printf '%s: Mach-O 64-bit arm64\n' "$1"
''';

const _brewStub = r'''
#!/bin/sh
case "$1" in
  --prefix)
    printf '%s\n' "$2" >>"$STATE_DIR/brew_prefix_calls"
    printf '%s/%s\n' "$FAKE_PREFIX" "$2"
    ;;
  list)
    if [ "$2" = "--versions" ]; then
      printf 'freetype 2.13.2\n'
      exit 0
    fi
    i=1
    while [ "$i" -le 40 ]; do
      printf 'filler%s\n' "$i"
      i=$((i + 1))
    done
    printf '%s\n' freetype brotli
    ;;
esac
exit 0
''';

const _codesignStub = r'''
#!/bin/sh
exit 0
''';

class _Sandbox {
  _Sandbox(this.root);

  final Directory root;

  late final Directory bin;
  late final Directory fixtures;
  late final Directory state;
  late final Directory opt;
  late final Directory app;

  static _Sandbox create() {
    final root = Directory.systemTemp.createTempSync(
      'bundle_ffmpeg_homebrew_deps_',
    );
    final sandbox = _Sandbox(root);
    sandbox.bin = Directory('${root.path}/bin')..createSync(recursive: true);
    sandbox.fixtures = Directory('${root.path}/fixtures')
      ..createSync(recursive: true);
    sandbox.state = Directory('${root.path}/state')
      ..createSync(recursive: true);
    sandbox.opt = Directory('${root.path}/opt')..createSync(recursive: true);
    sandbox.app = Directory('${root.path}/Enjoy Player.app')
      ..createSync(recursive: true);
    return sandbox;
  }

  String get frameworksDir => '${app.path}/Contents/Frameworks';

  void writeStub(String name, String body) {
    final file = File('${bin.path}/$name');
    file.writeAsStringSync(body);
    Process.runSync('chmod', ['+x', file.path]);
  }

  void writeDeps(String binary, List<String> deps) {
    File('${fixtures.path}/deps/$binary')
      ..createSync(recursive: true)
      ..writeAsStringSync('${deps.join('\n')}\n');
  }

  void writeRpaths(String binary, List<String> rpaths) {
    File('${fixtures.path}/rpaths/$binary')
      ..createSync(recursive: true)
      ..writeAsStringSync('${rpaths.join('\n')}\n');
  }

  void writeKegLib(String formula, String library) {
    File('${opt.path}/$formula/lib/$library')
      ..createSync(recursive: true)
      ..writeAsStringSync('mach-o');
  }

  void writeAppFile(String relativePath, String content) {
    File('${app.path}/$relativePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  void createAppDir(String relativePath) {
    Directory('${app.path}/$relativePath').createSync(recursive: true);
  }

  ProcessResult runBundler() {
    return Process.runSync(
      'bash',
      [_scriptPath, app.path],
      environment: {
        'PATH': '${bin.path}:${Platform.environment['PATH']}',
        'FIXTURE_DIR': fixtures.path,
        'STATE_DIR': state.path,
        'FAKE_PREFIX': opt.path,
        'CONFIGURATION': 'Debug',
        'CODE_SIGNING_ALLOWED': 'NO',
      },
      workingDirectory: Directory.current.path,
    );
  }

  List<String> depsOf(String binary) {
    final file = File('${fixtures.path}/deps/$binary');
    if (!file.existsSync()) return const [];
    return file
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  int brewPrefixCalls() {
    final file = File('${state.path}/brew_prefix_calls');
    if (!file.existsSync()) return 0;
    return file.readAsLinesSync().where((line) => line.isNotEmpty).length;
  }

  void dispose() {
    root.deleteSync(recursive: true);
  }
}

_Sandbox _buildSandbox({bool withBrotliCommon = true}) {
  final sandbox = _Sandbox.create();
  sandbox
    ..writeStub('otool', _otoolStub)
    ..writeStub('install_name_tool', _installNameToolStub)
    ..writeStub('file', _fileStub)
    ..writeStub('brew', _brewStub)
    ..writeStub('codesign', _codesignStub);

  sandbox.writeKegLib('freetype', _freetypeKegDylib);
  sandbox.writeKegLib('brotli', _brotlidecKegDylib);
  if (withBrotliCommon) {
    sandbox.writeKegLib('brotli', _brotlicommonKegDylib);
  }

  sandbox.writeDeps(_freetypeKegDylib, [
    '/opt/homebrew/opt/brotli/lib/$_brotlidecKegDylib',
    '/usr/lib/libSystem.B.dylib',
  ]);
  sandbox.writeDeps(_brotlidecKegDylib, [
    '@rpath/$_brotlicommonKegDylib',
    '/usr/lib/libSystem.B.dylib',
  ]);
  sandbox.writeDeps(_brotlicommonKegDylib, ['/usr/lib/libSystem.B.dylib']);
  sandbox.writeDeps('Enjoy Player', [
    '/opt/homebrew/opt/freetype/lib/$_freetypeKegDylib',
    '/usr/lib/libSystem.B.dylib',
  ]);

  sandbox.writeRpaths(_freetypeKegDylib, ['@loader_path']);
  sandbox.writeRpaths(_brotlidecKegDylib, [
    '@loader_path/../lib',
    '@loader_path',
  ]);
  sandbox.writeRpaths('Enjoy Player', ['@executable_path/../Frameworks']);

  sandbox.writeAppFile('Contents/MacOS/Enjoy Player', 'mach-o');
  sandbox.createAppDir('Contents/Frameworks');
  return sandbox;
}

void main() {
  final skipOnWindows = Platform.isWindows
      ? 'The bundler harness needs a POSIX shell.'
      : false;

  test(
    'bundles a dylib that is only reachable through an @rpath dependency',
    () {
      final sandbox = _buildSandbox();
      addTearDown(sandbox.dispose);

      final result = sandbox.runBundler();

      expect(
        result.exitCode,
        0,
        reason: 'bundler failed:\n${result.stdout}\n${result.stderr}',
      );
      expect(
        File('${sandbox.frameworksDir}/$_brotlicommonKegDylib').existsSync(),
        isTrue,
        reason:
            '$_brotlicommonKegDylib is only referenced as '
            '@rpath/$_brotlicommonKegDylib; the bundler has to copy it too.',
      );
      expect(
        File('${sandbox.frameworksDir}/$_brotlidecKegDylib').existsSync(),
        isTrue,
      );
      expect(
        sandbox.depsOf(_brotlidecKegDylib),
        contains('@rpath/$_brotlicommonKegDylib'),
      );
    },
    skip: skipOnWindows,
  );

  test("rewrites the app executable's Homebrew load command to an @rpath", () {
    final sandbox = _buildSandbox();
    addTearDown(sandbox.dispose);

    final result = sandbox.runBundler();

    expect(
      result.exitCode,
      0,
      reason: 'bundler failed:\n${result.stdout}\n${result.stderr}',
    );
    expect(
      sandbox.depsOf('Enjoy Player'),
      contains('@rpath/$_freetypeKegDylib'),
    );
  }, skip: skipOnWindows);

  test('fails the build when an @rpath dependency cannot be resolved', () {
    final sandbox = _buildSandbox(withBrotliCommon: false);
    addTearDown(sandbox.dispose);

    final result = sandbox.runBundler();

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains(_brotlicommonKegDylib),
      reason:
          'The closure check has to name the dependency that cannot be '
          'resolved, otherwise the release dies in dyld on the user machine.',
    );
  }, skip: skipOnWindows);

  test(
    'resolves a Homebrew dependency through its formula, not a full scan',
    () {
      final sandbox = _buildSandbox();
      addTearDown(sandbox.dispose);

      final result = sandbox.runBundler();

      expect(
        result.exitCode,
        0,
        reason: 'bundler failed:\n${result.stdout}\n${result.stderr}',
      );
      expect(
        sandbox.brewPrefixCalls(),
        lessThanOrEqualTo(4),
        reason:
            'The reference names its formula, so the bundler must ask that one '
            'keg instead of running "brew --prefix" for every installed formula '
            'on every dependency.',
      );
    },
    skip: skipOnWindows,
  );
}
