/// Shared auto-translate secondary text resolution helper.
///
/// Used by [TranscriptScrollableList] and [EchoRegionMergedCard] to avoid
/// duplicating the secondary text resolution and i18n fallback logic.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';

({String? secondaryText, bool canRetranslate, bool isFailed, bool isInFlight})
resolveAutoTranslateTextForDisplay({
  required bool autoTranslateActive,
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
  required int lineIndex,
  required String? sourceLanguage,
  required String? targetLanguage,
  required TranscriptSecondaryMatcher matcher,
  required TranscriptLine line,
  required bool Function(int lineIndex) isLineFailed,
  required bool Function(int lineIndex) isLineInFlight,
  String? l10nLineFailed,
  String? l10nLinePending,
}) {
  final raw = autoTranslateActive
      ? resolveAutoTranslateSecondaryText(
          primaryLines: primaryLines,
          aiLines: aiLines,
          lineIndex: lineIndex,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        )
      : matcher.match(line)?.text;
  final empty = raw == null || raw.trim().isEmpty;
  final failed = autoTranslateActive && isLineFailed(lineIndex);
  final inFlight = autoTranslateActive && isLineInFlight(lineIndex);

  final display = empty && l10nLineFailed != null
      ? (failed ? l10nLineFailed : (inFlight ? l10nLinePending : raw))
      : raw;

  final canRetranslate =
      autoTranslateActive &&
      (failed || (display != null && display.trim().isNotEmpty));

  return (
    secondaryText: display,
    canRetranslate: canRetranslate,
    isFailed: failed,
    isInFlight: inFlight,
  );
}
