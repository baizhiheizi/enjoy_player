import 'package:enjoy_player/data/api/services/ai/dictionary_api.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';

final class EnjoyDictionaryCapability implements DictionaryCapability {
  EnjoyDictionaryCapability(this._api);

  final DictionaryApi _api;

  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    final map = await _api.query(
      word: word,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      forceRefresh: forceRefresh,
    );
    return DictionaryResult.fromJson(map);
  }
}
