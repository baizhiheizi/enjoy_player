/// Request payload for transcript dictionary / translation lookup sheet.
library;

import 'package:enjoy_player/features/vocabulary/application/media_vocabulary_context_builder.dart';

final class LookupRequest {
  const LookupRequest({
    required this.selectedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.contextualContext,
    this.mediaVocabularyContext,
    this.sourceContext,
  });

  final String selectedText;
  final String sourceLanguage;
  final String targetLanguage;

  /// Surrounding transcript text for contextual translation (LLM).
  final String? contextualContext;

  /// Persistable media context for add-to-vocabulary (null when unavailable).
  final MediaVocabularyContext? mediaVocabularyContext;

  /// The line the word came from, for the sheet's "In this audio" block
  /// (null for non-transcript callers).
  final LookupSourceContext? sourceContext;

  LookupRequest copyWith({
    String? selectedText,
    String? sourceLanguage,
    String? targetLanguage,
    String? contextualContext,
    MediaVocabularyContext? mediaVocabularyContext,
  }) {
    return LookupRequest(
      selectedText: selectedText ?? this.selectedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      contextualContext: contextualContext ?? this.contextualContext,
      mediaVocabularyContext:
          mediaVocabularyContext ?? this.mediaVocabularyContext,
    );
  }
}

/// Display-only context for the lookup sheet's "In this audio" block.
final class LookupSourceContext {
  const LookupSourceContext({
    required this.isVideo,
    required this.startMs,
    required this.lineText,
  });

  final bool isVideo;
  final int startMs;
  final String lineText;
}
