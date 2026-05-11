import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';

abstract class TranslationCapability {
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  });
}
