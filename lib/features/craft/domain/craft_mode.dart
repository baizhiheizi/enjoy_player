/// Craft from text mode: translate-then-speak or speak-directly.
library;

/// Which Craft pipeline the learner selected.
enum CraftMode {
  /// Translate source text into the learning language, then synthesize.
  translateThenSpeak,

  /// Synthesize audio directly from learning-language text (no translation).
  speakDirectly;

  /// Whether this mode requires a source-language picker.
  bool get requiresSourceLanguage => this == CraftMode.translateThenSpeak;

  /// Whether this mode produces a secondary source-text transcript.
  bool get requiresSecondaryTranscript => this == CraftMode.translateThenSpeak;

  /// Storage value for [Audios.source] column.
  String get sourceFlag => switch (this) {
    CraftMode.translateThenSpeak => 'craft-translate',
    CraftMode.speakDirectly => 'craft-direct',
  };
}
