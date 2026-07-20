/// Persistable media vocabulary context from transcript + echo state.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/vocabulary_context_builder.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// Structured context for [VocabularyRepository.addWithContext].
final class MediaVocabularyContext {
  const MediaVocabularyContext({
    required this.text,
    required this.sourceType,
    required this.sourceId,
    required this.locator,
  });

  final String text;
  final VocabularySourceType sourceType;
  final String sourceId;
  final MediaLocator locator;
}

/// Builds text + media locator (ms) using the same span rules as AI context.
MediaVocabularyContext? buildMediaVocabularyContext({
  required List<TranscriptLine> lines,
  required EchoState echo,
  required double currentTimeSeconds,
  required String primaryLanguage,
  required VocabularySourceType sourceType,
  required String sourceId,
}) {
  final span = resolveVocabularyContextSpan(
    lines: lines,
    echo: echo,
    currentTimeSeconds: currentTimeSeconds,
    primaryLanguage: primaryLanguage,
  );
  if (span == null) return null;

  final startLine = lines[span.startLineIndex];
  final endLine = lines[span.endLineIndex];
  final startMs = startLine.startMs;
  final endMs = endLine.startMs + endLine.durationMs;
  final durationMs = (endMs - startMs).clamp(0, 1 << 31);

  return MediaVocabularyContext(
    text: span.text,
    sourceType: sourceType,
    sourceId: sourceId,
    locator: MediaLocator(start: startMs, duration: durationMs),
  );
}
