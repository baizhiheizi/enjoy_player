import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const translation = LookupTranslationParams(
    text: 'hello',
    sourceLanguage: 'en',
    targetLanguage: 'zh',
  );
  const dictionary = LookupDictionaryParams(
    text: 'hello',
    sourceLanguage: 'en',
    targetLanguage: 'zh',
  );
  const contextual = LookupContextualParams(
    text: 'hello',
    sourceLanguage: 'en',
    targetLanguage: 'zh',
    context: 'greeting',
  );

  test('same params derive the same key per section', () {
    expect(
      lookupTranslationCacheKey(translation),
      lookupTranslationCacheKey(
        const LookupTranslationParams(
          text: 'hello',
          sourceLanguage: 'en',
          targetLanguage: 'zh',
        ),
      ),
    );
    expect(
      lookupDictionaryCacheKey(dictionary),
      lookupDictionaryCacheKey(
        const LookupDictionaryParams(
          text: 'hello',
          sourceLanguage: 'en',
          targetLanguage: 'zh',
        ),
      ),
    );
    expect(
      lookupContextualTranslationCacheKey(contextual),
      lookupContextualTranslationCacheKey(
        const LookupContextualParams(
          text: 'hello',
          sourceLanguage: 'en',
          targetLanguage: 'zh',
          context: 'greeting',
        ),
      ),
    );
  });

  test('changed params derive a different key', () {
    expect(
      lookupTranslationCacheKey(translation),
      isNot(
        lookupTranslationCacheKey(
          const LookupTranslationParams(
            text: 'goodbye',
            sourceLanguage: 'en',
            targetLanguage: 'zh',
          ),
        ),
      ),
    );
    expect(
      lookupTranslationCacheKey(translation),
      isNot(lookupDictionaryCacheKey(dictionary)),
    );
  });

  test('contextual keys equate the omitted context with the empty context', () {
    final omitted = lookupContextualTranslationCacheKey(
      const LookupContextualParams(
        text: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      ),
    );
    final empty = lookupContextualTranslationCacheKey(
      const LookupContextualParams(
        text: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        context: '',
      ),
    );
    expect(omitted, empty);
    expect(omitted, isNot(lookupContextualTranslationCacheKey(contextual)));
  });
}
