import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_params.dart';
import 'package:enjoy_player/features/lookup/application/lookup_sheet_result_cache.dart';
import 'package:flutter_test/flutter_test.dart';

ContextualTranslationResult _ctxResult(String tag) => ContextualTranslationResult(
      translatedText: 'ctx-$tag',
    );

DictionaryResult _dictResult(String tag) => DictionaryResult(
      word: tag,
      sourceLanguage: tag,
      targetLanguage: tag,
      senses: const [],
    );

void main() {
  group('LookupSheetResultCache.evictForPair', () {
    test('removes only matching pair entries from both maps', () {
      final cache = LookupSheetResultCache();
      const pairA = (
        source: 'ko-KR',
        target: 'ja-JP',
      );
      const pairB = (
        source: 'ko-KR',
        target: 'es-ES',
      );
      const pairC = (
        source: 'ja-JP',
        target: 'ko-KR',
      );

      final ctxA = LookupContextualParams(
        text: '안녕',
        sourceLanguage: pairA.source,
        targetLanguage: pairA.target,
      );
      final ctxB = LookupContextualParams(
        text: '안녕',
        sourceLanguage: pairB.source,
        targetLanguage: pairB.target,
      );
      final ctxC = LookupContextualParams(
        text: 'こんにちは',
        sourceLanguage: pairC.source,
        targetLanguage: pairC.target,
      );
      final dictA = LookupDictionaryParams(
        word: '안녕',
        sourceLanguage: pairA.source,
        targetLanguage: pairA.target,
      );
      final dictB = LookupDictionaryParams(
        word: '안녕',
        sourceLanguage: pairB.source,
        targetLanguage: pairB.target,
      );
      final dictC = LookupDictionaryParams(
        word: 'こんにちは',
        sourceLanguage: pairC.source,
        targetLanguage: pairC.target,
      );

      cache
        ..rememberContextual(ctxA, _ctxResult(pairA.target))
        ..rememberContextual(ctxB, _ctxResult(pairB.target))
        ..rememberContextual(ctxC, _ctxResult(pairC.target))
        ..rememberDictionary(dictA, _dictResult(pairA.target))
        ..rememberDictionary(dictB, _dictResult(pairB.target))
        ..rememberDictionary(dictC, _dictResult(pairC.target));

      cache.evictForPair(
        sourceLanguage: pairA.source,
        targetLanguage: pairA.target,
      );

      expect(cache.peekContextual(ctxA), isNull);
      expect(cache.peekDictionary(dictA), isNull);
      expect(cache.peekContextual(ctxB), isNotNull);
      expect(cache.peekContextual(ctxC), isNotNull);
      expect(cache.peekDictionary(dictB), isNotNull);
      expect(cache.peekDictionary(dictC), isNotNull);
    });

    test('is a no-op when no entries match', () {
      final cache = LookupSheetResultCache();
      const ctx = LookupContextualParams(
        text: '안녕',
        sourceLanguage: 'ko-KR',
        targetLanguage: 'ja-JP',
      );
      cache.rememberContextual(ctx, _ctxResult('ja-JP'));

      cache.evictForPair(sourceLanguage: 'ko-KR', targetLanguage: 'es-ES');

      expect(cache.peekContextual(ctx), isNotNull);
    });
  });
}