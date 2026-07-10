/// Adapter: [CraftTranslator] backed by [TranslationService].
library;

import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';

final class CraftTranslationServiceTranslator implements CraftTranslator {
  CraftTranslationServiceTranslator(this._translation);

  final TranslationService _translation;

  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    TranslationStyle style = TranslationStyle.natural,
    String? customPrompt,
  }) async {
    // Append the style prompt suffix to the text for style-aware translation.
    final styleSuffix = style.promptSuffix;
    final effectiveText =
        style == TranslationStyle.custom && customPrompt != null
        ? '$customPrompt\n\n$text'
        : styleSuffix.isNotEmpty
        ? '$styleSuffix\n\n$text'
        : text;

    final result = await _translation.translate(
      text: effectiveText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    return result.translatedText;
  }
}
