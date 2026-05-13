/// In-memory cache for lookup sheet dictionary + contextual translation results.
///
/// Survives sheet close; use [evict*] before forced refetch. Keys are the same
/// [Lookup*Params] instances used by the lookup UI.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_params.dart';

part 'lookup_sheet_result_cache.g.dart';

final class LookupSheetResultCache {
  final _contextual = <LookupContextualParams, ContextualTranslationResult>{};
  final _dictionary = <LookupDictionaryParams, DictionaryResult>{};

  ContextualTranslationResult? peekContextual(LookupContextualParams params) =>
      _contextual[params];

  void rememberContextual(
    LookupContextualParams params,
    ContextualTranslationResult result,
  ) {
    _contextual[params] = result;
  }

  void evictContextual(LookupContextualParams params) {
    _contextual.remove(params);
  }

  DictionaryResult? peekDictionary(LookupDictionaryParams params) =>
      _dictionary[params];

  void rememberDictionary(LookupDictionaryParams params, DictionaryResult result) {
    _dictionary[params] = result;
  }

  void evictDictionary(LookupDictionaryParams params) {
    _dictionary.remove(params);
  }
}

@Riverpod(keepAlive: true)
LookupSheetResultCache lookupSheetResultCache(Ref ref) => LookupSheetResultCache();
