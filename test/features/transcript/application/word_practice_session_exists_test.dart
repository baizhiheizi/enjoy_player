import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:enjoy_player/features/transcript/application/word_practice_session.dart';

/// Counts how often the session provider's dependency was built, so a test
/// can prove that an existence check never initializes the session provider.
class _CountingIpaOverlaySettings extends IpaOverlaySettings {
  var builds = 0;

  @override
  Future<bool> build() async {
    builds++;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('word practice session existence guard', () {
    late _CountingIpaOverlaySettings ipa;
    late ProviderContainer container;

    setUp(() {
      ipa = _CountingIpaOverlaySettings();
      container = ProviderContainer(
        overrides: [ipaOverlaySettingsProvider.overrideWith(() => ipa)],
      );
    });

    tearDown(() => container.dispose());

    test('an uninitialized session provider reports no existence', () {
      expect(container.read(wordPracticeSessionProvider('m1').exists), isFalse);
    });

    test('an initialized session provider reports existence', () {
      container.read(wordPracticeSessionProvider('m1'));
      expect(container.read(wordPracticeSessionProvider('m1').exists), isTrue);
    });

    test('reading the existence guard does not initialize the provider', () {
      expect(container.read(wordPracticeSessionProvider('m1').exists), isFalse);
      expect(ipa.builds, 0);

      expect(container.read(wordPracticeSessionProvider('m1').exists), isFalse);
      expect(ipa.builds, 0);

      container.read(wordPracticeSessionProvider('m1'));
      expect(ipa.builds, 1);
      expect(container.read(wordPracticeSessionProvider('m1').exists), isTrue);
    });

    test('each media id is tracked independently', () {
      container.read(wordPracticeSessionProvider('m1'));

      expect(container.read(wordPracticeSessionProvider('m1').exists), isTrue);
      expect(container.read(wordPracticeSessionProvider('m2').exists), isFalse);
    });
  });
}
