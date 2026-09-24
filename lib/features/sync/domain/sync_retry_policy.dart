// One owner for the outbound `sync_queue` retry protocol (issue #752).
//
// The "permanently failed" threshold, the exponential backoff, and the wall
// clock the decision reads used to be spread across four files:
// `SyncEngine._kMaxRetries`/`_kRetryBaseMs` (library-private, so the
// repository could not share them), the hardcoded threshold literals in
// `SyncQueueRepository` (`pendingItems` / `watchSnapshot` / `resetFailed`),
// and the hardcoded write in `SyncQueueDao.markPermanentlyFailed` — plus a
// bare `DateTime.now()` hidden inside the old retry-decision helper.
// Changing the threshold in that shape silently diverged from the
// repository predicates and the DAO write (a moved threshold would leave
// "permanently failed" rows carrying the old value and looking retryable).
//
// All of it lives here now: engine, repository, and DAO derive their
// predicates and written retry count from this policy (the DAO takes the
// threshold as a parameter so `lib/data/db` never imports `lib/features`),
// and the decision reads the injectable clock — the in-repo precedent for
// that seam is `YouTubePlayRetryPolicy` in the player feature.
//
// Behavior is pinned to the pre-refactor defaults: `defaultMaxRetries` and
// `defaultBaseDelayMs` are the single spelling of each value in `lib/`.

import 'package:drift/drift.dart';

import 'package:enjoy_player/data/db/app_database.dart';

/// Retry threshold, backoff schedule, and wall clock for sync queue rows.
class SyncRetryPolicy {
  /// [now], [maxRetries], and [baseDelayMs] are injectable so tests can
  /// pin wall time and shrink the budget deterministically instead of
  /// sleeping past real backoff windows (issue #752).
  SyncRetryPolicy({DateTime Function()? now, int? maxRetries, int? baseDelayMs})
    : _now = now ?? DateTime.now,
      maxRetries = maxRetries ?? defaultMaxRetries,
      baseDelayMs = baseDelayMs ?? defaultBaseDelayMs;

  /// Behavior-preserving default: a row is permanently failed after this
  /// many attempts. The single threshold spelling in `lib/`.
  static const int defaultMaxRetries = 5;

  /// Behavior-preserving default base of the exponential backoff — the
  /// delay before attempt `retryCount + 1` is `baseDelayMs × 2^retryCount`.
  static const int defaultBaseDelayMs = 1000;

  /// The wall clock the retry decision reads. Defaults to [DateTime.now];
  /// tests inject a fixed function to make boundary cases deterministic.
  final DateTime Function() _now;

  /// Attempts before a row counts as permanently failed: a row with
  /// `retryCount >= maxRetries` is excluded from pending work. Also the
  /// value `SyncQueueDao.markPermanentlyFailed` writes (received as its
  /// `retryLimit` parameter).
  final int maxRetries;

  /// Base of the exponential backoff, in milliseconds.
  final int baseDelayMs;

  /// Dart form of the "permanently failed" threshold: a row with
  /// `retryCount >= maxRetries` has exhausted its retry budget.
  bool isPermanentlyFailed(int retryCount) => retryCount >= maxRetries;

  /// SQL form of [isPermanentlyFailed] so Drift predicates derive from the
  /// same threshold instead of restating it (issue #752).
  Expression<bool> permanentlyFailed(GeneratedColumn<int> retryCount) =>
      retryCount.isBiggerOrEqualValue(maxRetries);

  /// SQL complement of [permanentlyFailed] — rows still eligible for retry.
  Expression<bool> eligible(GeneratedColumn<int> retryCount) =>
      retryCount.isSmallerThanValue(maxRetries);

  /// Backoff before the next attempt: `baseDelayMs × 2^retryCount`
  /// (0 → 1000 ms, 1 → 2000 ms, 2 → 4000 ms, … with the defaults).
  ///
  /// Throws [RangeError] outside `0..30`, where the shift would overflow.
  int backoffDelayMs(int retryCount) {
    // Cap the exponent so `baseDelayMs * (1 << retryCount)` cannot overflow.
    RangeError.checkValueInInterval(retryCount, 0, 30, 'retryCount');
    return baseDelayMs * (1 << retryCount);
  }

  /// Whether [item]'s backoff window has elapsed, measured against the
  /// injected [now]. A row with no recorded attempt is immediately due.
  ///
  /// Threshold-agnostic: the drain's `pendingItems` already excludes
  /// permanently failed rows, so `_drainOnce` filters on this alone.
  bool backoffElapsed(SyncQueueRow item) {
    if (item.lastAttempt == null) return true;
    final elapsed = _now().difference(item.lastAttempt!).inMilliseconds;
    return elapsed >= backoffDelayMs(item.retryCount);
  }

  /// Full retry decision: not [isPermanentlyFailed] AND [backoffElapsed].
  ///
  /// `elapsed == delayMs` is eligible (the comparison is `>=`, matching the
  /// pre-refactor decision). No `DateTime.now()` on this path —
  /// time comes from the injected [now].
  bool shouldRetry(SyncQueueRow item) =>
      !isPermanentlyFailed(item.retryCount) && backoffElapsed(item);
}
