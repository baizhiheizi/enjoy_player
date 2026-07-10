import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('voicesForLanguage', () {
    test('returns multiple voices for English', () {
      final voices = voicesForLanguage('en');
      expect(voices.length, greaterThanOrEqualTo(4));
      expect(voices.every((v) => v.baseLang == 'en'), isTrue);
    });

    test('returns multiple voices for Chinese', () {
      final voices = voicesForLanguage('zh');
      expect(voices.length, greaterThanOrEqualTo(4));
    });

    test('returns voices for Japanese', () {
      final voices = voicesForLanguage('ja');
      expect(voices.length, greaterThanOrEqualTo(2));
    });

    test('returns voices for Korean', () {
      final voices = voicesForLanguage('ko');
      expect(voices.length, greaterThanOrEqualTo(2));
    });

    test('returns empty for unknown language', () {
      expect(voicesForLanguage('xx'), isEmpty);
    });

    test('is case-insensitive on base language', () {
      expect(voicesForLanguage('EN').length, voicesForLanguage('en').length);
    });
  });

  group('defaultVoiceForLanguage', () {
    test('returns a female voice for English by default', () {
      final voice = defaultVoiceForLanguage('en');
      expect(voice, isNotNull);
      expect(voice!.gender, 'female');
    });

    test('returns null for unknown language', () {
      expect(defaultVoiceForLanguage('xx'), isNull);
    });
  });

  group('AzureVoice', () {
    test('catalog has voices for all supported focus languages', () {
      for (final lang in ['en', 'zh', 'ja', 'ko', 'es', 'fr', 'de']) {
        expect(
          voicesForLanguage(lang),
          isNotEmpty,
          reason: 'No voices for $lang',
        );
      }
    });
  });
}
