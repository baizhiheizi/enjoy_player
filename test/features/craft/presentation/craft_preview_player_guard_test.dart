import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Craft owns a single preview playback implementation', () {
    final files = Directory('lib/features/craft')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    final playerOwners = files
        .where((file) => file.readAsStringSync().contains('AudioPlayer('))
        .map((file) => file.path)
        .toList();
    expect(playerOwners, [
      'lib/features/craft/application/craft_preview_controller.dart',
    ]);

    final privatePlayers = files
        .where(
          (file) => file.readAsStringSync().contains('class _PreviewPlayer'),
        )
        .map((file) => file.path)
        .toList();
    expect(privatePlayers, isEmpty);
  });
}
