import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:enjoy_player/core/platform/webview_software_gl_marker.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';

class _SupportDirProvider extends PathProviderPlatform {
  _SupportDirProvider(this.supportPath);

  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

void main() {
  late Directory support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('swgl_verdict_test');
    PathProviderPlatform.instance = _SupportDirProvider(support.path);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await support.delete(recursive: true);
  });

  File marker() =>
      File('${support.path}${Platform.pathSeparator}$softwareGlMarkerFileName');

  test(
    'the first verdict arms the marker and reports it to the caller',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final controller = PlayerController();

      expect(await controller.markSoftwareGlStallVerdict(), isTrue);
      expect(marker().existsSync(), isTrue);
    },
  );

  test(
    'a repeat verdict is dropped so the notice cannot double-fire',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final controller = PlayerController();

      expect(await controller.markSoftwareGlStallVerdict(), isTrue);
      expect(await controller.markSoftwareGlStallVerdict(), isFalse);
    },
  );

  test('a non-Linux platform never arms the marker', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final controller = PlayerController();

    expect(await controller.markSoftwareGlStallVerdict(), isFalse);
    expect(marker().existsSync(), isFalse);
  });
}
