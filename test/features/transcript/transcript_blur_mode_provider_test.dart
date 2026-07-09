import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptBlurMode', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to inactive', () {
      expect(container.read(transcriptBlurModeProvider), isFalse);
    });

    test('activate / deactivate / toggle', () {
      final ctrl = container.read(transcriptBlurModeProvider.notifier);
      ctrl.activate();
      expect(container.read(transcriptBlurModeProvider), isTrue);
      ctrl.activate();
      expect(container.read(transcriptBlurModeProvider), isTrue);
      ctrl.deactivate();
      expect(container.read(transcriptBlurModeProvider), isFalse);
      ctrl.toggle();
      expect(container.read(transcriptBlurModeProvider), isTrue);
      ctrl.toggle();
      expect(container.read(transcriptBlurModeProvider), isFalse);
    });

    test('restoreFromSession sets active from persisted flag', () {
      final ctrl = container.read(transcriptBlurModeProvider.notifier);
      ctrl.restoreFromSession(true);
      expect(container.read(transcriptBlurModeProvider), isTrue);
      ctrl.restoreFromSession(false);
      expect(container.read(transcriptBlurModeProvider), isFalse);
    });
  });
}
