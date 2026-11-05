import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AGP 9 pub plugin patcher', () {
    late Directory workspace;
    late Directory cache;
    late Directory repoRoot;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('agp9_patcher_test_');
      cache = Directory('${workspace.path}/cache')..createSync();
      repoRoot = Directory('${workspace.path}/repo')..createSync();
    });

    tearDown(() {
      if (workspace.existsSync()) workspace.deleteSync(recursive: true);
    });

    test('patches every built-in Kotlin target in the cache', () async {
      _writePackage(
        cache,
        'package_info_plus',
        '10.2.2',
        'android/build.gradle',
        _groovyBuildGradle,
      );
      _writePackage(
        cache,
        'wakelock_plus',
        '1.8.0',
        'android/build.gradle',
        _groovyBuildGradle,
      );
      _writePackage(
        cache,
        'url_launcher_android',
        '6.3.33',
        'android/build.gradle.kts',
        _ktsBuildGradle,
      );
      _writePackage(
        cache,
        'share_plus',
        '13.3.1',
        'android/build.gradle.kts',
        _sharePlusKts,
      );
      _writePackage(
        cache,
        'jni',
        '1.1.1',
        'android/build.gradle',
        _jniBuildGradle,
      );
      _writePackage(
        cache,
        'flutter_inappwebview_android',
        '1.2.0-beta.3',
        'android/build.gradle',
        _inappWebViewBuildGradle,
      );

      final result = _runPatcher(cache, repoRoot);
      expect(
        result.exitCode,
        0,
        reason: 'patcher failed: ${result.stdout}\n${result.stderr}',
      );

      final groovy = _readPackageFile(
        cache,
        'package_info_plus',
        '10.2.2',
        'android/build.gradle',
      );
      expect(groovy, isNot(contains("apply plugin: 'kotlin-android'")));
      expect(groovy, isNot(contains('ext.kotlin_version')));
      expect(groovy, isNot(contains('kotlin-gradle-plugin')));
      expect(groovy, isNot(contains('kotlin-stdlib')));
      expect(groovy, isNot(contains('kotlinOptions')));
      expect(groovy, contains("apply plugin: 'com.android.library'"));

      final kts = _readPackageFile(
        cache,
        'url_launcher_android',
        '6.3.33',
        'android/build.gradle.kts',
      );
      expect(kts, isNot(contains('id("kotlin-android")')));
      expect(kts, isNot(contains('kotlin-gradle-plugin')));
      expect(kts, contains('id("com.android.library")'));

      final sharePlus = _readPackageFile(
        cache,
        'share_plus',
        '13.3.1',
        'android/build.gradle.kts',
      );
      expect(
        sharePlus,
        contains('apply(plugin = "org.jetbrains.kotlin.android")'),
      );
      expect(sharePlus, isNot(contains('if (agpMajor < 9)')));

      final jni = _readPackageFile(
        cache,
        'jni',
        '1.1.1',
        'android/build.gradle',
      );
      expect(jni, isNot(contains('kotlin {')));
      expect(jni, isNot(contains('jvmTarget')));
      expect(jni, contains('compileSdk = 34'));

      final inapp = _readPackageFile(
        cache,
        'flutter_inappwebview_android',
        '1.2.0-beta.3',
        'android/build.gradle',
      );
      expect(inapp, contains('proguard-android-optimize.txt'));
      expect(inapp, isNot(contains('proguard-android.txt')));
    });

    test('clears the stale file_picker build output', () async {
      Directory(
        '${repoRoot.path}/build/file_picker',
      ).createSync(recursive: true);
      File(
        '${repoRoot.path}/build/file_picker/stale.bin',
      ).writeAsStringSync('x');

      final result = _runPatcher(cache, repoRoot);
      expect(result.exitCode, 0, reason: result.stderr);
      expect(
        Directory('${repoRoot.path}/build/file_picker').existsSync(),
        isFalse,
      );
    });

    test('leaves an unpatched cache untouched', () async {
      _writePackage(
        cache,
        'package_info_plus',
        '10.2.2',
        'android/build.gradle',
        _groovyBuildGradle,
      );
      final before = _readPackageFile(
        cache,
        'package_info_plus',
        '10.2.2',
        'android/build.gradle',
      );

      final result = _runPatcher(cache, repoRoot);
      expect(result.exitCode, 0, reason: result.stderr);

      final after = _readPackageFile(
        cache,
        'package_info_plus',
        '10.2.2',
        'android/build.gradle',
      );
      expect(after, isNot(before));
    });
  });

  group('patcher entry points stay drift-free', () {
    final root = _repoRoot();

    test('no entry point pins a package version', () {
      const packages = <String>[
        'package_info_plus',
        'wakelock_plus',
        'url_launcher_android',
        'share_plus',
        'jni',
        'flutter_inappwebview_android',
      ];
      for (final path in <String>[
        'tool/patch_agp9_pub_plugins.sh',
        'tool/patch_agp9_pub_plugins.ps1',
        'tool/patch_agp9_pub_plugins.dart',
      ]) {
        final source = File('${root.path}/$path').readAsStringSync();
        for (final package in packages) {
          expect(
            source,
            isNot(matches(RegExp('${RegExp.escape(package)}-[0-9]'))),
            reason: '$path pins a version of $package',
          );
        }
      }
    });

    test('the shell wrappers carry no patch logic of their own', () {
      final bash = File(
        '${root.path}/tool/patch_agp9_pub_plugins.sh',
      ).readAsStringSync();
      final powershell = File(
        '${root.path}/tool/patch_agp9_pub_plugins.ps1',
      ).readAsStringSync();
      expect(bash, isNot(contains('sed ')));
      expect(bash, isNot(contains('perl ')));
      expect(powershell, isNot(contains('-replace')));
      expect(powershell, isNot(contains('[regex]')));
    });

    test(
      'the wrapper falls back to the Dart SDK of the Flutter SDK on PATH',
      () {
        final bash = _which('bash');
        final dirname = _which('dirname');
        if (bash == null || dirname == null) {
          markTestSkipped('no bash on PATH');
          return;
        }
        final sdk = Directory.systemTemp.createTempSync('agp9_flutter_sdk_');
        addTearDown(() => sdk.deleteSync(recursive: true));

        final binDir = Directory('${sdk.path}/bin')
          ..createSync(recursive: true);
        Link('${binDir.path}/dirname').createSync(dirname);
        final dartDir = Directory('${sdk.path}/bin/cache/dart-sdk/bin')
          ..createSync(recursive: true);
        final dartStub = File('${dartDir.path}/dart')
          ..writeAsStringSync(r'''#!/bin/sh
echo "dart-stub $@"
''');
        Process.runSync('chmod', <String>['+x', dartStub.path]);

        final flutterStub = File('${binDir.path}/flutter')
          ..writeAsStringSync(r'''#!/bin/sh
exit 0
''');
        Process.runSync('chmod', <String>['+x', flutterStub.path]);

        final result = Process.runSync(
          bash,
          <String>['${root.path}/tool/patch_agp9_pub_plugins.sh'],
          workingDirectory: root.path,
          environment: <String, String>{'PATH': binDir.path},
          includeParentEnvironment: false,
        );

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        expect(result.stdout, contains('dart-stub'));
        expect(result.stdout, contains('patch_agp9_pub_plugins.dart'));
      },
    );
  });
}

String? _which(String name) {
  final separator = Platform.isWindows ? ';' : ':';
  for (final dir in (Platform.environment['PATH'] ?? '').split(separator)) {
    if (dir.isEmpty) continue;
    final candidate = File('$dir/$name');
    if (candidate.existsSync()) return candidate.path;
  }
  return null;
}

ProcessResult _runPatcher(Directory cache, Directory repoRoot) {
  final root = _repoRoot();
  return Process.runSync('bash', <String>[
    '${root.path}/tool/patch_agp9_pub_plugins.sh',
    '--pub-cache',
    cache.path,
    '--repo-root',
    repoRoot.path,
  ], workingDirectory: root.path);
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('could not locate the package root from ${dir.path}');
    }
    dir = parent;
  }
  return dir;
}

void _writePackage(
  Directory cache,
  String package,
  String version,
  String relativePath,
  String content,
) {
  final file = File('${cache.path}/$package-$version/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _readPackageFile(
  Directory cache,
  String package,
  String version,
  String relativePath,
) => File('${cache.path}/$package-$version/$relativePath').readAsStringSync();

const String _groovyBuildGradle = '''
group 'dev.fluttercommunity.plus.package_info_plus'
version '1.0'

buildscript {
    ext.kotlin_version = '1.8.22'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk8:\$kotlin_version"
}
''';

const String _ktsBuildGradle = '''
group = "dev.fluttercommunity.plus.url_launcher_android"
version = "1.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}
''';

const String _sharePlusKts = '''
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val agpMajor = 9

if (agpMajor < 9) {
    apply(plugin = "org.jetbrains.kotlin.android")
}
''';

const String _jniBuildGradle = '''
group = "dev.dart.flutter"
version = "1.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
    }
}

apply plugin: 'com.android.library'

android {
    compileSdk = 34
}

kotlin {
    compilerOptions {
        jvmTarget = "1.8"
    }
}
''';

const String _inappWebViewBuildGradle = '''
group 'io.flutter.plugins'
version '1.0'

apply plugin: 'com.android.library'

android {
    consumerProguardFiles 'proguard-android.txt'
}
''';
