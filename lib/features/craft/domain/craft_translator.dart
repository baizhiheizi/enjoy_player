/// Translation port for the Craft flow (testable abstraction over TranslationService).
library;

/// Abstract translation interface consumed by [CraftController].
///
/// The adapter implementation wraps [TranslationService.translate] so the
/// controller stays testable without a live AI capability stack.
abstract interface class CraftTranslator {
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  });
}
