import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Craft failure rendering stays in the shared failure widgets', () {
    final sharedWidget = File(
      'lib/features/craft/presentation/widgets/craft_failure_card.dart',
    ).absolute.path;
    final offenders = Directory('lib/features/craft/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !p.equals(file.absolute.path, sharedWidget))
        .where((file) => file.readAsStringSync().contains('.message(l10n)'))
        .map((file) => file.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'Render failures with CraftFailureCard or CraftInlineFailure.',
    );
  });
}
