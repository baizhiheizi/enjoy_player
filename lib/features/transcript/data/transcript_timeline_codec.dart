/// One home for the `timelineJson` contract: decode (strict + fail-closed),
/// content-keyed memoization, and active-cue lookup (issue #766).
///
/// ADR-0070 §"one JSON contract" used to hold only in the `TranscriptLine`
/// model — the JSON was decoded by three independent decoders with two
/// private memo caches (repository, Craft enricher, player interactions).
/// Everything now crosses this module; cue lookups live here too so the two
/// policies (UI highlight, transport) share one binary-search core instead
/// of drifting.
///
/// Both decodes pass through [TranscriptLine.fromJson], so the mixed-unit
/// rule (word offsets in ms relative to the line; phone offsets in seconds
/// absolute) is checked on every path, not just some.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../data/subtitle/transcript_line.dart';

/// Timelines larger than this are decoded in a background isolate before
/// [TranscriptTimelineCache.linesFor] serves them synchronously.
const int kPreloadTimelineJsonBytes = 16 * 1024;

/// Decodes a `timelineJson` blob from the `transcripts` table.
///
/// Strict by design: DB rows are the trusted source of truth, so a malformed
/// shape (non-list JSON, non-map items) throws instead of silently dropping
/// lines. Callers handling untrusted input use [tryDecodeTimelineJson].
List<TranscriptLine> decodeTimelineJson(String timelineJson) {
  final decoded = (jsonDecode(timelineJson) as List)
      .cast<Map<String, dynamic>>();
  return decoded.map(TranscriptLine.fromJson).toList();
}

/// Fail-closed decode for untrusted timelines (Craft enrichment input).
///
/// Returns `null` on a malformed shape — including a list that mixes valid
/// lines with garbage — so the caller falls back to the original JSON
/// instead of enriching a partial decode. Partial input is treated as
/// garbage deliberately: a dropped line desynchronizes line indices from
/// alignment segments, and the fail-closed path is cheaper than trusting a
/// half-decoded timeline.
///
/// Catches exactly the parse errors the decode can produce —
/// [FormatException] from `jsonDecode` and [TypeError] from the lazy
/// `.cast<Map<String, dynamic>>()` / `fromJson` field casts. Anything else
/// (an `Error` from a broken VM, OOM, …) propagates: fail-closed means
/// "fail-closed on parse errors", not "swallow every conceivable failure".
List<TranscriptLine>? tryDecodeTimelineJson(String timelineJson) {
  try {
    return decodeTimelineJson(timelineJson);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

/// Content hash used as the memo identity for a `timelineJson` blob.
///
/// The full SHA-1 (40 hex chars, 160 bits), deliberately NOT truncated: the
/// hash is the identity gate between a cached decode and a fresh one for the
/// same row id, so a collision would return the WRONG lines for a row — the
/// stale-line-index bug class this module exists to prevent (issue #659).
/// At 64 bits a birthday collision is plausible within a heavy session; at
/// 160 bits it is not. The extra 24 hex chars per entry are noise.
String timelineJsonHash(String timelineJson) =>
    sha1.convert(utf8.encode(timelineJson)).toString();

class _CachedLines {
  const _CachedLines(this.hash, this.lines);
  final String hash;
  final List<TranscriptLine> lines;
}

/// Memoized timeline decode keyed on row identity + content hash.
///
/// Keying on content — not the row id alone — is the issue-#659
/// re-segmentation guard: a re-import re-segments cues under the *same* row
/// id, the changed `timelineJson` hashes differently, and the cache serves a
/// fresh decode instead of stale line indices. The hash-on-content key also
/// skips re-decoding when an unrelated Drift bump shifts a row's
/// `updatedAt` without touching `timelineJson`.
///
/// Eviction: entries are removed on the row's mutation points —
/// `_deleteTranscript`, `_replaceTimeline`, and the auto-translate rewrite
/// paths call [remove] (see `transcript_repository_tracks.dart` /
/// `transcript_repository_auto_translate.dart`). Between mutations the
/// population is bounded by the number of DISTINCT transcript rows decoded
/// this session (one entry per row id — re-decodes overwrite, never add),
/// so growth tracks the user's transcript library, not playback time; no
/// LRU on top.
class TranscriptTimelineCache {
  final Map<String, _CachedLines> _entries = {};

  /// Decoded lines for `(rowId, timelineJson)`, memoized.
  List<TranscriptLine> linesFor({
    required String rowId,
    required String timelineJson,
  }) {
    final hash = timelineJsonHash(timelineJson);
    final hit = _entries[rowId];
    if (hit != null && hit.hash == hash) return hit.lines;
    final decoded = decodeTimelineJson(timelineJson);
    _entries[rowId] = _CachedLines(hash, decoded);
    return decoded;
  }

  /// Whether `(rowId, timelineJson)` already holds a decode.
  bool isCached({required String rowId, required String timelineJson}) {
    final hit = _entries[rowId];
    return hit != null && hit.hash == timelineJsonHash(timelineJson);
  }

  /// Stores a decode produced off the UI isolate (background preload).
  void store({
    required String rowId,
    required String timelineJson,
    required List<TranscriptLine> lines,
  }) {
    _entries[rowId] = _CachedLines(timelineJsonHash(timelineJson), lines);
  }

  /// Evicts a row's decode (row deleted or its timeline rewritten without
  /// going through [linesFor]).
  void remove(String rowId) => _entries.remove(rowId);

  void clear() => _entries.clear();
}

/// Active cue index for [t] in seconds — the **UI highlight policy**:
/// the largest index whose cue starts at or before [t] (binary search).
///
/// Assumes [lines] are ordered by [TranscriptLine.startSeconds] (normal
/// transcript order). In a gap or past the last cue this still returns the
/// preceding cue so the highlight persists instead of blinking out.
int transcriptActiveIndex(List<TranscriptLine> lines, double t) {
  if (lines.isEmpty) return -1;

  var lo = 0;
  var hi = lines.length - 1;
  var rightmost = -1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    final s = lines[mid].startSeconds;
    if (s <= t) {
      rightmost = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  return rightmost;
}

/// Active cue index for [t] in seconds — the **transport policy**:
/// the first cue that strictly contains [t] (`start <= t < end`), falling
/// back to the highlight policy's rightmost-start cue.
///
/// Used by line navigation / echo activation (`PlayerInteractions`), where
/// containment-first matters for overlapping cues: the earliest containing
/// cue is the one a user tapping at [t] means to replay.
int indexOfActiveLine(List<TranscriptLine> lines, double t) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (t >= line.startSeconds && t < line.endSeconds) {
      return i;
    }
  }
  return transcriptActiveIndex(lines, t);
}
