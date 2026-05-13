/// Async data for dictionary lookup sheet sections (cached by Riverpod family).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_params.dart';
import 'package:enjoy_player/features/lookup/application/lookup_sheet_result_cache.dart';

export 'lookup_section_params.dart';

part 'lookup_section_providers.g.dart';

@riverpod
Future<TranslationResult> lookupSheetTranslation(
  Ref ref,
  LookupTranslationParams params,
) async {
  return ref
      .read(translationServiceProvider)
      .translate(
        text: params.text,
        sourceLanguage: params.sourceLanguage,
        targetLanguage: params.targetLanguage,
      );
}

@riverpod
Future<DictionaryResult> lookupSheetDictionary(
  Ref ref,
  LookupDictionaryParams params,
) async {
  final cache = ref.read(lookupSheetResultCacheProvider);
  final cached = cache.peekDictionary(params);
  if (cached != null) return cached;

  final result = await ref
      .read(dictionaryServiceProvider)
      .lookup(
        word: params.word,
        sourceLanguage: params.sourceLanguage,
        targetLanguage: params.targetLanguage,
      );
  cache.rememberDictionary(params, result);
  return result;
}
