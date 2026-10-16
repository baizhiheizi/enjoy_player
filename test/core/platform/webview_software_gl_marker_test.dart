import 'dart:io';

import 'package:enjoy_player/core/platform/webview_software_gl_marker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('swgl_marker_test');
  });

  tearDown(() async {
    await support.delete(recursive: true);
  });

  test('creates the marker file the Linux runner checks', () async {
    final persisted = await markSoftwareGlForNextLaunch(
      supportDirectory: support,
    );

    expect(persisted, isTrue);
    expect(
      File(
        '${support.path}${Platform.pathSeparator}$softwareGlMarkerFileName',
      ).existsSync(),
      isTrue,
    );
  });

  test('is idempotent across repeated verdicts', () async {
    expect(
      await markSoftwareGlForNextLaunch(supportDirectory: support),
      isTrue,
    );
    expect(
      await markSoftwareGlForNextLaunch(supportDirectory: support),
      isTrue,
    );
  });

  test('creates a missing support directory', () async {
    final nested = Directory('${support.path}${Platform.pathSeparator}nested');

    final persisted = await markSoftwareGlForNextLaunch(
      supportDirectory: nested,
    );

    expect(persisted, isTrue);
    expect(
      File(
        '${nested.path}${Platform.pathSeparator}$softwareGlMarkerFileName',
      ).existsSync(),
      isTrue,
    );
  });

  test('returns false when the marker cannot be written', () async {
    final blocker = File(
      '${support.path}${Platform.pathSeparator}$softwareGlMarkerFileName',
    );
    await blocker.create();

    final persisted = await markSoftwareGlForNextLaunch(
      supportDirectory: Directory(
        '${blocker.path}${Platform.pathSeparator}child',
      ),
    );

    expect(persisted, isFalse);
  });
}
