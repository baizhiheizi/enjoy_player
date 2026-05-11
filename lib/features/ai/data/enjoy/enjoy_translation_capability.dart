import 'package:enjoy_player/data/api/services/ai/translation_api.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';

final class EnjoyTranslationCapability implements TranslationCapability {
  EnjoyTranslationCapability(this._api);

  final TranslationApi _api;

  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    final map = await _api.translate(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      forceRefresh: forceRefresh,
    );
    final translated =
        map['translatedText'] as String? ?? map['translated_text'] as String? ?? '';
    return TranslationResult(
      translatedText: translated,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }
}
