import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/domain/sync_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

SyncQueueRow _row({required int retryCount, DateTime? lastAttempt}) {
  return SyncQueueRow(
    id: 1,
    entityType: 'audio',
    entityId: 'a1',
    action: 'create',
    payloadJson: '{}',
    createdAt: DateTime(2026, 1, 1),
    retryCount: retryCount,
    lastAttempt: lastAttempt,
    error: null,
  );
}

void main() {
  // Far beyond the real wall clock (tests run in 2026): if any decision read
  // a bare DateTime.now() instead of the injected clock, elapsed would be
  // hugely negative and every expectation below would flip to false.
  final fakeNow = DateTime.utc(2030, 6, 1);

  group('SyncRetryPolicy threshold', () {
    test(
      'defaults pin the pre-refactor behavior (threshold 5, base 1000 ms)',
      () {
        final policy = SyncRetryPolicy();
        expect(policy.maxRetries, 5);
        expect(policy.baseDelayMs, 1000);
        expect(SyncRetryPolicy.defaultMaxRetries, 5);
        expect(SyncRetryPolicy.defaultBaseDelayMs, 1000);
      },
    );

    test('isPermanentlyFailed flips exactly at maxRetries', () {
      final policy = SyncRetryPolicy();
      expect(policy.isPermanentlyFailed(policy.maxRetries - 1), isFalse);
      expect(policy.isPermanentlyFailed(policy.maxRetries), isTrue);
      expect(policy.isPermanentlyFailed(policy.maxRetries + 1), isTrue);
    });

    test('a permanently failed row never retries, regardless of the clock', () {
      final policy = SyncRetryPolicy(now: () => fakeNow);
      expect(
        policy.shouldRetry(
          _row(
            retryCount: policy.maxRetries,
            lastAttempt: fakeNow.subtract(const Duration(days: 1)),
          ),
        ),
        isFalse,
      );
    });
  });

  group('SyncRetryPolicy backoff', () {
    test('delay is baseDelayMs × 2^retryCount', () {
      final policy = SyncRetryPolicy();
      expect(policy.backoffDelayMs(0), 1000);
      expect(policy.backoffDelayMs(1), 2000);
      expect(policy.backoffDelayMs(2), 4000);
      expect(policy.backoffDelayMs(3), 8000);
      expect(policy.backoffDelayMs(4), 16000);
    });

    test(
      'backoffDelayMs rejects retryCount outside 0..30 (no shift overflow)',
      () {
        final policy = SyncRetryPolicy();
        expect(() => policy.backoffDelayMs(-1), throwsRangeError);
        expect(() => policy.backoffDelayMs(31), throwsRangeError);
        expect(() => policy.backoffDelayMs(1 << 10), throwsRangeError);
        // In-range values still yield the pinned schedule.
        expect(policy.backoffDelayMs(0), 1000);
        expect(policy.backoffDelayMs(1), 2000);
        expect(policy.backoffDelayMs(2), 4000);
        expect(policy.backoffDelayMs(3), 8000);
        expect(policy.backoffDelayMs(4), 16000);
        expect(policy.backoffDelayMs(30), 1000 * (1 << 30));
      },
    );

    test('elapsed == delayMs exactly is eligible (deterministic boundary)', () {
      final policy = SyncRetryPolicy(now: () => fakeNow);
      // retryCount 1 → delay 2000 ms.
      final delay = policy.backoffDelayMs(1);
      expect(
        policy.shouldRetry(
          _row(
            retryCount: 1,
            lastAttempt: fakeNow.subtract(Duration(milliseconds: delay)),
          ),
        ),
        isTrue,
      );
      expect(
        policy.shouldRetry(
          _row(
            retryCount: 1,
            lastAttempt: fakeNow.subtract(Duration(milliseconds: delay - 1)),
          ),
        ),
        isFalse,
      );
    });

    test('backoff window shortens relatively as retryCount grows', () {
      final policy = SyncRetryPolicy(now: () => fakeNow);
      final attemptAt = fakeNow.subtract(const Duration(milliseconds: 3000));
      // 3000 ms elapsed clears the 2000 ms window (retryCount 1)…
      expect(
        policy.shouldRetry(_row(retryCount: 1, lastAttempt: attemptAt)),
        isTrue,
      );
      // …but not the 4000 ms window (retryCount 2).
      expect(
        policy.shouldRetry(_row(retryCount: 2, lastAttempt: attemptAt)),
        isFalse,
      );
    });

    test('a row with no recorded attempt is immediately due', () {
      final policy = SyncRetryPolicy(now: () => fakeNow);
      expect(policy.backoffElapsed(_row(retryCount: 0)), isTrue);
      expect(policy.shouldRetry(_row(retryCount: 0)), isTrue);
    });

    test('backoffElapsed is threshold-agnostic (drain filter half)', () {
      final policy = SyncRetryPolicy(now: () => fakeNow);
      final exhausted = _row(
        retryCount: policy.maxRetries,
        lastAttempt: fakeNow.subtract(const Duration(days: 1)),
      );
      expect(policy.backoffElapsed(exhausted), isTrue);
      expect(policy.shouldRetry(exhausted), isFalse);
    });
  });

  group('SyncRetryPolicy injected clock', () {
    test('decision reads the injected clock, not DateTime.now', () {
      // lastAttempt sits between the fake clock's delay and where the real
      // clock would put it: only the injected clock yields "eligible".
      final policy = SyncRetryPolicy(now: () => fakeNow);
      final row = _row(
        retryCount: 4, // delay 16000 ms
        lastAttempt: fakeNow.subtract(const Duration(milliseconds: 16000)),
      );
      expect(policy.shouldRetry(row), isTrue);

      // Same row against a clock that has not caught up yet → blocked.
      final lagging = SyncRetryPolicy(
        now: () => fakeNow.subtract(const Duration(milliseconds: 1)),
      );
      expect(lagging.shouldRetry(row), isFalse);
    });
  });
}
