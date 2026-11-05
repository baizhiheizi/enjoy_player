/// Single-source AGP 9 pub-cache patcher for the Flutter Android plugins.
///
/// Every host runs this one implementation. `tool/patch_agp9_pub_plugins.sh`
/// and `tool/patch_agp9_pub_plugins.ps1` are thin wrappers that exec it, so
/// the patch logic cannot drift between shells.
///
/// Targets are matched by package name and globbed by version, so a resolved
/// dependency bump never needs an edit here.
///
/// The rationale for each patch lives in [docs/packaging.md].
library;

import 'dart:io';

/// The kind of Gradle edit a target receives.
enum _PatchKind {
  /// Groovy `build.gradle`: drop the built-in Kotlin plugin wiring.
  kotlinGroovy,

  /// Kotlin `build.gradle.kts`: drop the built-in Kotlin plugin wiring.
  kotlinKts,

  /// Kotlin `build.gradle.kts`: apply KGP unconditionally (AGP 9 skips it).
  sharePlusAgp9,

  /// Groovy `build.gradle`: drop the dead `kotlin { }` block.
  jniKotlinBlock,

  /// Groovy `build.gradle`: point at the optimized ProGuard file.
  proguardRename,
}

/// A pub package whose Android Gradle file is patched.
final class _Target {
  const _Target(this.package, this.kind, this.relativePath);

  final String package;
  final _PatchKind kind;
  final String relativePath;
}

const List<_Target> _targets = <_Target>[
  _Target('package_info_plus', _PatchKind.kotlinGroovy, 'android/build.gradle'),
  _Target('wakelock_plus', _PatchKind.kotlinGroovy, 'android/build.gradle'),
  _Target(
    'url_launcher_android',
    _PatchKind.kotlinKts,
    'android/build.gradle.kts',
  ),
  _Target('share_plus', _PatchKind.sharePlusAgp9, 'android/build.gradle.kts'),
  _Target('jni', _PatchKind.jniKotlinBlock, 'android/build.gradle'),
  _Target(
    'flutter_inappwebview_android',
    _PatchKind.proguardRename,
    'android/build.gradle',
  ),
];

const String _hostedSuffix = 'hosted/pub.dev';

final RegExp _mentionsKotlin = RegExp(
  r'kotlin-android|org\.jetbrains\.kotlin\.android',
);

final RegExp _groovyDirective = RegExp(
  r'^\s*(?:'
  r'apply plugin:\s*[\x27\x22]kotlin-android[\x27\x22]\s*$'
  r'|classpath\s+[\x27\x22]org\.jetbrains\.kotlin:kotlin-gradle-plugin'
  r'|classpath\(\s*[\x27\x22]org\.jetbrains\.kotlin:kotlin-gradle-plugin'
  r'|implementation\s+[\x27\x22]org\.jetbrains\.kotlin:kotlin-stdlib'
  r'|ext\.kotlin_version\s*='
  r')',
);

final RegExp _kotlinOptionsOpen = RegExp(r'kotlinOptions\s*\{');

final RegExp _ktsDirective = RegExp(
  r'^\s*(?:'
  r'id\([\x27\x22]kotlin-android[\x27\x22]\)\s*$'
  r'|classpath\(\s*[\x27\x22]org\.jetbrains\.kotlin:kotlin-gradle-plugin'
  r')',
);

final RegExp _agpMajorGuard = RegExp(r'agpMajor\s*<\s*9');

final RegExp _sharePlusConditional = RegExp(
  r'if\s*\(\s*agpMajor\s*<\s*9\s*\)\s*\{\s*'
  r'apply\(plugin\s*=\s*[\x27\x22]org\.jetbrains\.kotlin\.android[\x27\x22]\)\s*\}',
  dotAll: true,
);

final RegExp _kotlinBlockOpen = RegExp(r'^kotlin\s*\{');

final RegExp _kotlinBlockClose = RegExp(r'^\}');

/// Command-line options for the patcher.
final class _Options {
  const _Options({this.pubCache, this.repoRoot});

  /// The directory that directly holds the `<package>-<version>` folders.
  final String? pubCache;

  /// The repository root whose `build/` folder is pruned.
  final String? repoRoot;

  static _Options parse(List<String> args) {
    String? pubCache;
    String? repoRoot;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--pub-cache':
          pubCache = _valueAfter(args, ++i, '--pub-cache');
        case '--repo-root':
          repoRoot = _valueAfter(args, ++i, '--repo-root');
        default:
          throw FormatException('Unknown argument: ${args[i]}');
      }
    }
    return _Options(pubCache: pubCache, repoRoot: repoRoot);
  }

  static String _valueAfter(List<String> args, int index, String flag) {
    if (index >= args.length) {
      throw FormatException('$flag requires a directory argument');
    }
    return args[index];
  }
}

void main(List<String> args) {
  final _Options options;
  try {
    options = _Options.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('patch_agp9_pub_plugins: ${e.message}');
    exitCode = 64;
    return;
  }

  final String? cacheRoot = options.pubCache ?? _resolvePubCacheRoot();
  if (cacheRoot == null) {
    stderr.writeln(
      'Pub cache not found. Pass --pub-cache <dir> or run `flutter pub get`.',
    );
    exitCode = 1;
    return;
  }

  final repoRoot = options.repoRoot ?? _defaultRepoRoot();
  final cache = Directory(cacheRoot);
  if (!cache.existsSync()) {
    stderr.writeln('Pub cache not found at $cacheRoot');
    exitCode = 1;
    return;
  }

  var sharePlusPatched = false;
  for (final target in _targets) {
    for (final dir in _packageDirs(cache, target.package)) {
      final patched = _patchPackage(dir, target);
      if (patched && target.kind == _PatchKind.sharePlusAgp9) {
        sharePlusPatched = true;
      }
    }
  }

  if (sharePlusPatched) {
    _removeBuildDir('$repoRoot/build/share_plus');
  }
  _removeBuildDir('$repoRoot/build/file_picker');

  stdout.writeln('AGP 9 pub plugin patches applied.');
}

/// The `hosted/pub.dev` directory of the local pub cache, or null when the
/// cache cannot be located.
String? _resolvePubCacheRoot() {
  final roots = <String>[
    if (Platform.environment['PUB_CACHE'] case final env?
        when env.trim().isNotEmpty)
      env.trim(),
    '${Platform.environment['HOME'] ?? ''}/.pub-cache',
    if (Platform.environment['LOCALAPPDATA'] case final local?
        when local.trim().isNotEmpty)
      '$local/Pub/Cache',
  ];
  for (final root in roots) {
    final candidate = _withHostedSuffix(root);
    if (Directory(candidate).existsSync()) return candidate;
  }
  return null;
}

String _withHostedSuffix(String root) {
  final normalized = root.replaceAll('\\', '/');
  if (normalized.endsWith(_hostedSuffix)) return root;
  return '$root/$_hostedSuffix';
}

/// The repository root, derived from this script's location.
String _defaultRepoRoot() {
  try {
    final script = Platform.script;
    if (script.scheme == 'file') {
      return File.fromUri(script).parent.parent.path;
    }
  } on Object catch (_) {}
  return Directory.current.path;
}

/// Every `<package>-<version>` directory in the cache for [package].
List<Directory> _packageDirs(Directory cache, String package) {
  final prefix = '$package-';
  final result = <Directory>[];
  for (final entity in cache.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final name = entity.path.split(Platform.pathSeparator).last;
    if (!name.startsWith(prefix)) continue;
    result.add(entity);
  }
  return result;
}

/// Applies [target]'s patch to the package directory [dir]. Returns whether
/// the file was rewritten.
bool _patchPackage(Directory dir, _Target target) {
  final file = File('${dir.path}/${target.relativePath}');
  if (!file.existsSync()) return false;
  final original = file.readAsStringSync();
  final patched = switch (target.kind) {
    _PatchKind.kotlinGroovy => _stripKotlinGroovy(original),
    _PatchKind.kotlinKts => _stripKotlinKts(original),
    _PatchKind.sharePlusAgp9 => _patchSharePlusAgp9(original),
    _PatchKind.jniKotlinBlock => _stripJniKotlinBlock(original),
    _PatchKind.proguardRename => _renameProguardFile(original),
  };
  if (patched == original) return false;
  file.writeAsStringSync(patched);
  stdout.writeln('Patched ${target.package}: ${file.path}');
  return true;
}

/// Removes the built-in Kotlin plugin wiring from a Groovy `build.gradle`.
String _stripKotlinGroovy(String text) {
  if (!_mentionsKotlin.hasMatch(text)) return text;
  final kept = <String>[];
  var inKotlinOptions = false;
  for (final line in text.split('\n')) {
    if (inKotlinOptions) {
      if (line.contains('}')) inKotlinOptions = false;
      continue;
    }
    if (_groovyDirective.hasMatch(line)) continue;
    if (_kotlinOptionsOpen.hasMatch(line)) {
      inKotlinOptions = !line.contains('}');
      continue;
    }
    kept.add(line);
  }
  return kept.join('\n');
}

/// Removes the built-in Kotlin plugin wiring from a Kotlin `build.gradle.kts`.
String _stripKotlinKts(String text) {
  if (!_mentionsKotlin.hasMatch(text)) return text;
  final kept = <String>[];
  for (final line in text.split('\n')) {
    if (_ktsDirective.hasMatch(line)) continue;
    kept.add(line);
  }
  return kept.join('\n');
}

/// Applies the Kotlin Gradle plugin unconditionally.
String _patchSharePlusAgp9(String text) {
  if (!_agpMajorGuard.hasMatch(text)) return text;
  return text.replaceFirst(
    _sharePlusConditional,
    'apply(plugin = "org.jetbrains.kotlin.android")',
  );
}

/// Removes the dead `kotlin { }` block from a Groovy `build.gradle`.
String _stripJniKotlinBlock(String text) {
  final lines = text.split('\n');
  if (!lines.any(_kotlinBlockOpen.hasMatch)) return text;
  final kept = <String>[];
  var inBlock = false;
  for (final line in lines) {
    if (inBlock) {
      if (_kotlinBlockClose.hasMatch(line)) inBlock = false;
      continue;
    }
    if (_kotlinBlockOpen.hasMatch(line)) {
      inBlock = true;
      continue;
    }
    kept.add(line);
  }
  return kept.join('\n');
}

/// Points the plugin at the optimized ProGuard rules file.
String _renameProguardFile(String text) =>
    text.replaceAll('proguard-android.txt', 'proguard-android-optimize.txt');

void _removeBuildDir(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return;
  dir.deleteSync(recursive: true);
  stdout.writeln('Cleared stale $path');
}
