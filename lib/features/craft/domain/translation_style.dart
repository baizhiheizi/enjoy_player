/// Translation style presets for the Craft translate tool.
library;

/// Named style presets that map to LLM prompt suffixes.
///
/// Ported from the web app's `TranslationStyle` type
/// (`apps/web/src/types/db/common.ts`).
enum TranslationStyle {
  literal,
  natural,
  casual,
  formal,
  simplified,
  detailed,
  custom;

  /// Prompt instruction appended to the base translation request.
  /// Empty for [custom] — the learner supplies their own prompt.
  String get promptSuffix => switch (this) {
    TranslationStyle.literal =>
      'Translate the text as literally as possible, preserving the original sentence structure.',
    TranslationStyle.natural =>
      'Translate the text naturally, as a fluent speaker would say it.',
    TranslationStyle.casual =>
      'Translate the text in a casual, conversational tone.',
    TranslationStyle.formal =>
      'Translate the text in a formal, professional register.',
    TranslationStyle.simplified =>
      'Translate using simple vocabulary and short sentences suitable for beginners.',
    TranslationStyle.detailed =>
      'Translate with additional context and nuance, explaining idioms if needed.',
    TranslationStyle.custom => '',
  };

  /// Whether this style reveals the custom prompt input.
  bool get showsCustomPrompt => this == TranslationStyle.custom;

  /// ARB key for the localized label.
  String get l10nKey => switch (this) {
    TranslationStyle.literal => 'craftStyleLiteral',
    TranslationStyle.natural => 'craftStyleNatural',
    TranslationStyle.casual => 'craftStyleCasual',
    TranslationStyle.formal => 'craftStyleFormal',
    TranslationStyle.simplified => 'craftStyleSimplified',
    TranslationStyle.detailed => 'craftStyleDetailed',
    TranslationStyle.custom => 'craftStyleCustom',
  };
}
