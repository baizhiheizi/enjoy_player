import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';

abstract class DictionaryCapability {
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  });
}
