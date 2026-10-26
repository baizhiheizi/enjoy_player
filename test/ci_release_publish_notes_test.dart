import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workflow = File(
    '.github/workflows/release_publish.yml',
  ).readAsStringSync();

  test(
    'release_publish.yml extracts the Unreleased section for the release body',
    () {
      expect(
        workflow,
        contains(r'/^## \[Unreleased\]/{flag=1;next} /^## \[/{flag=0} flag'),
        reason:
            'The notes fallback must slice the ## [Unreleased] section out of '
            'CHANGELOG.md (ADR-0067 § 2), not publish the whole file as the '
            'release body.',
      );
      expect(workflow, isNot(contains('notes_path="CHANGELOG.md"')));
    },
  );

  test(
    'release_publish.yml fails loudly when CHANGELOG.md has no Unreleased section',
    () {
      expect(
        workflow,
        contains("CHANGELOG.md has no '## [Unreleased]' section to publish."),
      );
    },
  );
}
