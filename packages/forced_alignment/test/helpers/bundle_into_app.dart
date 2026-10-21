/// Runs the vendored `bundle_into_app.sh` against [appPath].
///
/// [platformName] selects the destination layout (`macosx` puts the data in
/// `Contents/Resources/espeak-ng-data`, `iphoneos` in
/// `Runner.app/espeak-ng-data`). Signing is disabled because the test only
/// inspects the produced layout.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void runBundleScript(
  String script,
  String appPath, {
  required String platformName,
}) {
  final result = Process.runSync(
    script,
    [appPath],
    environment: {'PLATFORM_NAME': platformName, 'CODE_SIGNING_ALLOWED': 'NO'},
  );
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
}
