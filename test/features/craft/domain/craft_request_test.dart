import 'package:enjoy_player/features/craft/domain/craft_mode.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeCraftText', () {
    test('collapses whitespace runs', () {
      expect(normalizeCraftText('hello    world\n\n\tfoo'), 'hello world foo');
    });

    test('trims leading and trailing whitespace', () {
      expect(normalizeCraftText('  hello  '), 'hello');
    });

    test('empty string stays empty', () {
      expect(normalizeCraftText(''), '');
    });

    test('whitespace-only returns empty', () {
      expect(normalizeCraftText('   \n\t  '), '');
    });
  });

  group('craftDedupeKey', () {
    test('includes mode name, language, and text', () {
      final key = craftDedupeKey(
        mode: CraftMode.speakDirectly,
        learningLanguage: 'en',
        normalizedText: 'hello',
      );
      expect(key, 'speakDirectly|en|hello');
    });

    test('different modes produce different keys', () {
      final direct = craftDedupeKey(
        mode: CraftMode.speakDirectly,
        learningLanguage: 'en',
        normalizedText: 'hello',
      );
      final translate = craftDedupeKey(
        mode: CraftMode.translateThenSpeak,
        learningLanguage: 'en',
        normalizedText: 'hello',
      );
      expect(direct, isNot(equals(translate)));
    });
  });

  group('CraftMode', () {
    test('speakDirectly does not require source language', () {
      expect(CraftMode.speakDirectly.requiresSourceLanguage, isFalse);
    });

    test('translateThenSpeak requires source language', () {
      expect(CraftMode.translateThenSpeak.requiresSourceLanguage, isTrue);
    });

    test('sourceFlag values are distinct', () {
      expect(CraftMode.speakDirectly.sourceFlag, 'craft-direct');
      expect(CraftMode.translateThenSpeak.sourceFlag, 'craft-translate');
    });
  });

  group('craft constants', () {
    test('min text length is 10', () {
      expect(craftMinTextLength, 10);
    });

    test('max text length is 5000', () {
      expect(craftMaxTextLength, 5000);
    });
  });
}
