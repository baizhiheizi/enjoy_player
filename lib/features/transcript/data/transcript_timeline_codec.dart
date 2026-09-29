/// One home for the `timelineJson` contract: decode (strict + fail-closed),
/// revision-keyed memoization, size-gated encode, and active-cue lookup
/// (issue #766; memo key reworked for issue #810 D5).
///
/// ADR-0070 §"one JSON contract" used to hold only in the `TranscriptLine`
/// model — the JSON was decoded by three independent decoders with two
/// private memo caches (repository, Craft enricher, player interactions).
/// Everything now crosses this module; cue lookups live here too so the two
/// policies (UI highlight, transport) share one binary-search core instead of
/// drifting.
///
/// Both decodes pass through [TranscriptLine.fromJson], so the mixed-unit
/// rule (word offsets in ms relative to the line; phone offsets in seconds
/// absolute) is checked on every path, not just some.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;

import '../../../core/cache/lru_store.dart';
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

/// [decodeTimelineJson] that leaves the UI isolate (via [compute]) when the
/// payload exceeds [kPreloadTimelineJsonBytes] — the gate behind the
/// repository's line preload, shared with the Craft listing path.
Future<List<TranscriptLine>> decodeTimelineJsonGated(String timelineJson) {
  if (timelineJson.length <= kPreloadTimelineJsonBytes) {
    return Future.value(decodeTimelineJson(timelineJson));
  }
  return compute(
    decodeTimelineJson,
    timelineJson,
    debugLabel: 'timeline-json-decode',
  );
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

/// Encodes [lines] as a `timelineJson` blob (the write-side counterpart of
/// [decodeTimelineJson]).
String encodeTimelineJson(List<TranscriptLine> lines) =>
    jsonEncode([for (final line in lines) line.toJson()]);

/// Timelines whose encoded size is estimated above this are encoded in a
/// background isolate by [encodeTimelineJsonGated] (issue #810 D4 — the
/// read side already had this gate, the write side had none).
const int kEncodeTimelineJsonBytes = 16 * 1024;

/// Encodes [lines] in a background isolate when the payload is large
/// (mirroring the read-side [kPreloadTimelineJsonBytes] gate), inline
/// otherwise.
Future<String> encodeTimelineJsonGated(List<TranscriptLine> lines) {
  if (timelineEncodeNeedsIsolate(lines)) {
    return compute(encodeTimelineJson, lines);
  }
  return Future.value(encodeTimelineJson(lines));
}

/// Whether [encodeTimelineJsonGated] would leave the calling isolate for
/// [lines].
bool timelineEncodeNeedsIsolate(List<TranscriptLine> lines) =>
    estimatedTimelineJsonBytes(lines) > kEncodeTimelineJsonBytes;

/// Upper-bound estimate of the encoded byte length of [lines] — a UTF-8
/// code unit costs at most three bytes, and every JSON field name and
/// delimiter is covered by the fixed per-entry terms. Only used to pick the
/// encode path, so overestimating is safe and underestimating is impossible
/// up to these constants.
int estimatedTimelineJsonBytes(List<TranscriptLine> lines) {
  var bytes = 64;
  for (final line in lines) {
    bytes += 64 + 3 * line.text.length;
    final words = line.timeline;
    if (words == null) continue;
    for (final word in words) {
      bytes += 48 + 3 * word.text.length + 96 * (word.phones?.length ?? 0);
    }
  }
  return bytes;
}

/// Per-row content revision for a `transcripts` row: the pair changes
/// whenever the row's `timeline_json` changes, because drift stores
/// `updated_at` at whole-second granularity and
/// `TranscriptDao.upsert`/`upsertAll` nudge a same-second consecutive write
/// one second forward (issue #810 D5).
typedef TranscriptTimelineRevision = ({DateTime updatedAt, int jsonLength});

/// Maximum number of decoded timelines kept memoized; the least-recently
/// used decode is dropped on overflow (issue #810, item C1).
const int kTranscriptTimelineMemoCapacity = 8;

class _CachedLines {
  const _CachedLines(this.revision, this.lines);
  final TranscriptTimelineRevision revision;
  final List<TranscriptLine> lines;
}

/// Memoized timeline decode keyed on row identity + content revision.
///
/// The revision key replaces the previous SHA-1-over-JSON identity
/// (issue #810 D5): hashing a 1–10 MB enriched timeline ran up to three
/// times per DB tick (`isCached`, `store`, `linesFor` on every watch
/// re-run), all on the UI isolate. A revision compare is two field
/// comparisons.
///
/// Soundness of the key rests on a DAO invariant, not on caller discipline:
/// `TranscriptDao` guarantees two consecutive stored writes to the same row
/// never share a stored `updated_at` second, so any content change —
/// including a same-length edit landing in the same wall-clock second, and
/// re-segmentation under the same row id (issue #659) — changes the
/// revision and forces a re-decode. Writes that bypass the DAO have no such
/// guarantee.
///
/// Eviction: entries are removed on the row's mutation points —
/// `_deleteTranscript`, `_replaceTimeline`, and the auto-translate rewrite
/// paths call [remove] (see `transcript_repository_tracks.dart` /
/// `transcript_repository_auto_translate.dart`) — and the memo set is
/// bounded by an [L1Store] LRU of [kTranscriptTimelineMemoCapacity] rows
/// with no TTL (issue #810, item C1): age never invalidates a memo entry,
/// and the least-recently-used decode is dropped on overflow and
/// re-decoded on demand, so decoding many distinct transcripts in one
/// session no longer keeps every decode resident.
class TranscriptTimelineCache {
  final L1Store<String, _CachedLines> _entries = L1Store<String, _CachedLines>(
    capacity: kTranscriptTimelineMemoCapacity,
  );

  /// Decoded lines for `(rowId, revision)`, memoized; [timelineJson] is
  /// only decoded on a miss.
  List<TranscriptLine> linesFor({
    required String rowId,
    required TranscriptTimelineRevision revision,
    required String timelineJson,
  }) {
    final hit = _entries.peek(rowId);
    if (hit != null && hit.revision == revision) return hit.lines;
    final decoded = decodeTimelineJson(timelineJson);
    _entries.put(rowId, _CachedLines(revision, decoded));
    return decoded;
  }

  /// Whether `(rowId, revision)` already holds a decode.
  ///
  /// A pure probe: unlike [linesFor] it does not touch the entry's LRU
  /// position, so a background pre-decode gate cannot keep a row resident
  /// or reorder the eviction queue.
  bool isCached({
    required String rowId,
    required TranscriptTimelineRevision revision,
  }) {
    final hit = _entries.peekNoTouch(rowId);
    return hit != null && hit.revision == revision;
  }

  /// Stores a decode produced off the UI isolate (background preload).
  void store({
    required String rowId,
    required TranscriptTimelineRevision revision,
    required List<TranscriptLine> lines,
  }) {
    _entries.put(rowId, _CachedLines(revision, lines));
  }

  /// Evicts a row's decode (row deleted or its timeline rewritten without
  /// going through [linesFor]).
  void remove(String rowId) => _entries.invalidate(rowId);
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
