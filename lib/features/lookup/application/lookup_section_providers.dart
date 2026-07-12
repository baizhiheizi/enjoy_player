/// Async data for dictionary lookup sheet sections (cached by Riverpod family
/// and the shared `AiResultCache` hierarchy — see issue #311).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/ai/application/ai_cache_fingerprint.dart';
import 'package:enjoy_player/features/ai/application/ai_result_cache.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_params.dart';

export 'lookup_section_params.dart';

part 'lookup_section_providers.g.dart';

@riverpod
Future<TranslationResult> lookupSheetTranslation(
  Ref ref,
  LookupTranslationParams params, {
  bool forceRefresh = false,
}) async {
  final cache = ref.read(aiTranslationCacheProvider);
  final key = AiCacheFingerprint.fingerprint(
    kind: AiKind.translation.wire,
    payload: {
      'text': params.text,
      'sourceLanguage': params.sourceLanguage,
      'targetLanguage': params.targetLanguage,
    },
  );
  return cache.lookup(
    kind: AiKind.translation,
    key: key,
    loader: () => ref
        .read(translationServiceProvider)
        .translate(
          text: params.text,
          sourceLanguage: params.sourceLanguage,
          targetLanguage: params.targetLanguage,
        ),
    forceRefresh: forceRefresh,
  );
}

@riverpod
Future<DictionaryResult> lookupSheetDictionary(
  Ref ref,
  LookupDictionaryParams params, {
  bool forceRefresh = false,
}) async {
  final cache = ref.read(aiDictionaryCacheProvider);
  final key = AiCacheFingerprint.fingerprint(
    kind: AiKind.dictionary.wire,
    payload: {
      'word': params.text,
      'sourceLanguage': params.sourceLanguage,
      'targetLanguage': params.targetLanguage,
    },
  );
  return cache.lookup(
    kind: AiKind.dictionary,
    key: key,
    loader: () => ref
        .read(dictionaryServiceProvider)
        .lookup(
          word: params.text,
          sourceLanguage: params.sourceLanguage,
          targetLanguage: params.targetLanguage,
        ),
    forceRefresh: forceRefresh,
  );
}
