import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workflow = File(
    '.github/workflows/release_publish.yml',
  ).readAsStringSync();

  test(
    'release_publish.yml checks out the resolved tag for the release body',
    () {
      expect(workflow, contains(r'ref: ${{ steps.tag.outputs.tag }}'));
    },
  );

  test(
    'release_publish.yml reaches the notes step via env, not step-local shell vars',
    () {
      expect(workflow, contains(r'TAG: ${{ steps.tag.outputs.tag }}'));
      expect(workflow, contains(r'version="${TAG#v}"'));
      expect(workflow, isNot(contains(r'version="${tag#v}"')));
    },
  );

  test(
    'release_publish.yml extracts the version section, not the whole CHANGELOG',
    () {
      expect(
        workflow,
        contains(
          r'index($0, section) == 1 {flag=1; next} /^## \[/ {flag=0} flag',
        ),
        reason:
            'The notes fallback must slice the ## [<version>] section out of '
            'the CHANGELOG.md at the tag (ADR-0067 § 2), not publish the '
            'whole file as the release body.',
      );
      expect(workflow, isNot(contains('notes_path="CHANGELOG.md"')));
    },
  );

  test(
    'release_publish.yml fails loudly when the tag has no version section',
    () {
      expect(workflow, contains("has no '\${section}' section to publish."));
    },
  );
}
