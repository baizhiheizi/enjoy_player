/// Adapter: [CraftTranslator] backed by [TranslationService].
library;

import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';

final class CraftTranslationServiceTranslator implements CraftTranslator {
  CraftTranslationServiceTranslator(this._translation);

  final TranslationService _translation;

  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final result = await _translation.translate(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    return result.translatedText;
  }
}
