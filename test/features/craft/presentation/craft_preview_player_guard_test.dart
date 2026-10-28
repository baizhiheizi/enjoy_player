import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Craft owns a single preview playback implementation', () {
    final sources = {
      for (final file
          in Directory('lib/features/craft')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart')))
        file.path.replaceAll(Platform.pathSeparator, '/'): file
            .readAsStringSync(),
    };

    final playerOwners = sources.entries
        .where((entry) => RegExp(r'\bAudioPlayer\s*\(').hasMatch(entry.value))
        .map((entry) => entry.key)
        .toList();
    expect(playerOwners, [
      'lib/features/craft/application/craft_preview_controller.dart',
    ], reason: 'Construct AudioPlayer only in CraftPreviewController.');

    final audioPlayersImports = sources.entries
        .where(
          (entry) =>
              entry.key !=
              'lib/features/craft/application/craft_preview_controller.dart',
        )
        .where(
          (entry) => RegExp(
            r"import\s+'package:audioplayers/audioplayers\.dart';",
          ).hasMatch(entry.value),
        )
        .map((entry) => entry.key)
        .toList();
    expect(
      audioPlayersImports,
      isEmpty,
      reason: 'Use CraftPreviewPlayer instead of importing audioplayers.',
    );
  });
}
