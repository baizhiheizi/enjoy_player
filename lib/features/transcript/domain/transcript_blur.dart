/// Domain models and pure helpers for the transcript blur (practice /
/// listening-focus) feature.
///
/// No Flutter imports — safe to use from `data/`, `application/`,
/// tests, and the player engine. The cue identity helper
/// [cueIdFor] is the single source of truth for which
/// `TranscriptLine` corresponds to which blur-reveal provider entry.
library;

import 'package:meta/meta.dart';

import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

/// Fixed tap-reveal hold duration (seconds). Not user-configurable.
const int kTapRevealHoldSeconds = 3;

/// Ephemeral record describing the currently-tap-revealed cue.
///
/// At most ONE `TapRevealHold` exists per `mediaId` at any time. Tapping
/// a new cue replaces the hold; the prior cue re-blurs on the next
/// frame because the per-cue reveal provider compares against this
/// single record.
@immutable
class TapRevealHold {
  const TapRevealHold({required this.cueId, required this.expiresAt});

  /// Stable cue identity produced by [cueIdFor].
  final String cueId;

  /// Wall-clock instant at which the hold expires. Compared against
  /// `DateTime.now()` (UTC) by the cue reveal provider.
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) => now.isBefore(expiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TapRevealHold &&
          other.cueId == cueId &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(cueId, expiresAt);
}

/// Stable identity for a [TranscriptLine] for use as the blur-reveal
/// provider key, the tap-reveal hold key, and equality assertions in
/// tests.
///
/// Markup (`<font>`, `<b>`, `<i>`, `<br>`, etc.) is stripped before
/// hashing so two cues that differ only in inline markup map to the
/// same id. Empty / null text maps to a deterministic sentinel id that
/// never collides with real cue ids.
String cueIdFor(TranscriptLine line) {
  final start = line.startMs;
  final end = line.startMs + line.durationMs;
  final plain = plainTextFromSubtitleMarkup(line.text).trim();
  if (plain.isEmpty) {
    return '__invalid__:$start:$end';
  }
  // Short FNV-1a 32-bit hash of the trimmed plain text. Avoids pulling
  // in `crypto` for a non-cryptographic identity. Inline keeps the
  // helper allocation-free for the common case (no `Iterable` build).
  var hash = 0x811c9dc5;
  for (final code in plain.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return '$start:$end:${hash.toRadixString(16)}';
}
