/// One owner for the outbound `sync_queue` retry protocol (issue #752).
///
/// The "permanently failed" threshold, the exponential backoff, and the wall
/// clock the decision reads used to be spread across four files:
/// `SyncEngine._kMaxRetries`/`_kRetryBaseMs` (library-private, so the
/// repository could not share them), the hardcoded threshold literals in
/// `SyncQueueRepository` (`pendingItems` / `watchSnapshot` / `resetFailed`),
/// and the `SyncQueueDao.markPermanentlyFailed` sentinel — plus a bare
/// `DateTime.now()` hidden inside `shouldRetryQueueItem`. Changing the
/// threshold in that shape silently diverged from the repository predicates
/// and the DAO sentinel (a moved threshold would leave "permanently failed"
/// rows carrying the old sentinel and looking retryable).
///
/// All of it lives here now: engine, repository, and DAO derive their
/// predicates/sentinel from this policy (the DAO takes the sentinel as a
/// parameter so `lib/data/db` never imports `lib/features`), and the
/// decision reads the injectable clock — the in-repo precedent for that seam
/// is `YouTubePlayRetryPolicy` in the player feature.
///
/// Behavior is pinned to the pre-refactor defaults: [defaultMaxRetries] and
/// [defaultBaseDelayMs] are the single spelling of each value in `lib/`.
library;

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
  /// `retryCount >= maxRetries` is excluded from pending work.
  final int maxRetries;

  /// Base of the exponential backoff, in milliseconds.
  final int baseDelayMs;

  /// Sentinel `retry_count` written when a row is marked permanently failed
  /// (`SyncQueueDao.markPermanentlyFailed` receives it as a parameter).
  ///
  /// Equals [maxRetries] by construction, so the sentinel, the
  /// `pendingItems` / `watchSnapshot` / `resetFailed` predicates, and the
  /// decision below can never disagree about what "permanently failed" means.
  int get sentinel => maxRetries;

  /// Whether a row with [retryCount] has exhausted its retry budget.
  bool isPermanentlyFailed(int retryCount) => retryCount >= maxRetries;

  /// Backoff before the next attempt: `baseDelayMs × 2^retryCount`
  /// (0 → 1000 ms, 1 → 2000 ms, 2 → 4000 ms, … with the defaults).
  int backoffDelayMs(int retryCount) => baseDelayMs * (1 << retryCount);

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
  /// pre-refactor `shouldRetryQueueItem`). No `DateTime.now()` on this path —
  /// time comes from the injected [now].
  bool shouldRetry(SyncQueueRow item) =>
      !isPermanentlyFailed(item.retryCount) && backoffElapsed(item);
}
