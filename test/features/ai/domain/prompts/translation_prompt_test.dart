// Coverage for lib/features/ai/domain/prompts/translation_prompt.dart.
//
// The translation prompt is a tiny pure-function module — the tests pin
// language-base handling and the user-prompt passthrough. (The YouTube
// state-poll coverage that used to live here moved to
// youtube_js_protocol_channel_test.dart with the protocol seam, issue #767.)
import 'package:enjoy_player/features/ai/domain/prompts/translation_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildTranslationSystemPrompt', () {
    test('mentions source/target language base tags', () {
      final prompt = buildTranslationSystemPrompt(
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      expect(prompt, contains('en'));
      expect(prompt, contains('zh'));
    });

    test('asks for translation-only output', () {
      final prompt = buildTranslationSystemPrompt(
        sourceLanguage: 'fr',
        targetLanguage: 'de',
      );
      expect(prompt.toLowerCase(), contains('only the translated text'));
      expect(prompt.toLowerCase(), contains('no quotes'));
    });

    test('extracts BCP-47 base tag', () {
      final prompt = buildTranslationSystemPrompt(
        sourceLanguage: 'zh-CN',
        targetLanguage: 'en-US',
      );
      expect(prompt, contains('zh'));
      expect(prompt, contains('en'));
    });

    test('is deterministic', () {
      final a = buildTranslationSystemPrompt(
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      final b = buildTranslationSystemPrompt(
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      expect(a, b);
    });
  });

  group('buildTranslationUserPrompt', () {
    test('returns the text verbatim', () {
      expect(buildTranslationUserPrompt('bonjour'), 'bonjour');
    });

    test('preserves empty input', () {
      expect(buildTranslationUserPrompt(''), '');
    });

    test('preserves unicode', () {
      expect(buildTranslationUserPrompt('你好'), '你好');
    });

    test('preserves multi-line text', () {
      const multiline = 'line one\nline two\nline three';
      expect(buildTranslationUserPrompt(multiline), multiline);
    });
  });
}
