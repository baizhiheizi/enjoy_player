import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forced_alignment/forced_alignment.dart';
import 'package:forced_alignment/src/synth/espeak_synth_host.dart';

import 'helpers/bundle_into_app.dart';

/// eSpeak-NG pins its data directory the first time `espeak_Initialize`
/// runs, so a synthesis that resolves a *different* data path afterwards
/// still reads the pinned one. This file therefore owns the only synthesis
/// against a bundled app: it runs in its own process, so the pinned path is
/// the bundled one and the assertion below really exercises it.
void main() {
  test('macOS app-bundle dylib still synthesizes a spoken reference', () async {
    if (!Platform.isMacOS) return;
    final repoNative = resolveEspeakLibraryPath();
    final repoData = resolveEspeakDataPath();
    expect(repoNative, isNotNull);
    expect(repoData, isNotNull);

    final tmp = Directory.systemTemp.createTempSync('espeak-bundle-synth-');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final app = Directory('${tmp.path}/Enjoy Player.app');
    Directory('${app.path}/Contents/MacOS').createSync(recursive: true);
    final macFrameworks = Directory('${app.path}/Contents/Frameworks')
      ..createSync();
    File(repoNative!).copySync('${macFrameworks.path}/libespeak-ng.dylib');
    final script = File(
      '${Directory(repoData!).parent.path}/bundle_into_app.sh',
    );
    expect(script.existsSync(), isTrue, reason: script.path);
    runBundleScript(script.path, app.path, platformName: 'macosx');

    final bundledLib = File(
      '${app.path}/Contents/Frameworks/libespeak-ng.dylib',
    );
    final bundledData = Directory(
      '${app.path}/Contents/Resources/espeak-ng-data',
    );
    expect(bundledLib.existsSync(), isTrue);
    expect(bundledData.existsSync(), isTrue);
    expect(missingEspeakRequiredDataFiles(bundledData.path), isEmpty);

    setEspeakNativePathOverrides(
      libraryPath: bundledLib.path,
      dataPath: bundledData.path,
    );
    addTearDown(setEspeakNativePathOverrides);

    final ref = await EspeakSynthHost.synthesize(
      text: 'hello',
      language: 'en-US',
    );
    expect(ref.pcm, isNotEmpty);
    expect(ref.words, isNotEmpty);
  });
}
