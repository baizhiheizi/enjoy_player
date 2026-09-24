import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/domain/sync_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

SyncQueueRow _row({
  required int id,
  int retryCount = 0,
  DateTime? lastAttempt,
  String entityType = 'audio',
  String entityId = 'a1',
  String action = 'create',
  DateTime? createdAt,
}) {
  return SyncQueueRow(
    id: id,
    entityType: entityType,
    entityId: entityId,
    action: action,
    payloadJson: '{}',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    retryCount: retryCount,
    lastAttempt: lastAttempt,
    error: null,
  );
}

void main() {
  group('sortSyncQueueWork', () {
    test('orders delete before create for the same entity', () {
      final create = _row(
        id: 1,
        entityType: 'video',
        entityId: 'v1',
        action: 'create',
        createdAt: DateTime(2026, 1, 1),
      );
      final delete = _row(
        id: 2,
        entityType: 'video',
        entityId: 'v1',
        action: 'delete',
        createdAt: DateTime(2026, 1, 2),
      );
      final work = [create, delete];
      sortSyncQueueWork(work);
      expect(work.map((r) => r.action), ['delete', 'create']);
    });
  });

  group('policy.shouldRetry', () {
    // Fixed wall clock: the decision reads the policy's injected now, so
    // these cases no longer fabricate lastAttempt values around the real
    // clock (issue #752).
    final fakeNow = DateTime.utc(2030, 6, 1);
    final policy = SyncRetryPolicy(now: () => fakeNow);

    test('allows first attempt when lastAttempt is null', () {
      expect(policy.shouldRetry(_row(id: 1)), isTrue);
    });

    test('blocks permanently failed rows (retryCount >= maxRetries)', () {
      expect(
        policy.shouldRetry(_row(id: 1, retryCount: policy.maxRetries)),
        isFalse,
      );
      expect(
        policy.shouldRetry(_row(id: 1, retryCount: policy.maxRetries - 1)),
        isTrue,
      );
    });

    test('applies exponential backoff from lastAttempt', () {
      // retryCount 1 → delay 2000 ms.
      expect(
        policy.shouldRetry(_row(id: 1, retryCount: 1, lastAttempt: fakeNow)),
        isFalse,
      );
      expect(
        policy.shouldRetry(
          _row(
            id: 1,
            retryCount: 1,
            lastAttempt: fakeNow.subtract(const Duration(seconds: 3)),
          ),
        ),
        isTrue,
      );
    });

    test('elapsed == delayMs exactly is eligible', () {
      // retryCount 1 → delay 2000 ms; exactly 2000 ms elapsed passes.
      expect(
        policy.shouldRetry(
          _row(
            id: 1,
            retryCount: 1,
            lastAttempt: fakeNow.subtract(const Duration(milliseconds: 2000)),
          ),
        ),
        isTrue,
      );
      expect(
        policy.shouldRetry(
          _row(
            id: 1,
            retryCount: 1,
            lastAttempt: fakeNow.subtract(const Duration(milliseconds: 1999)),
          ),
        ),
        isFalse,
      );
    });

    test('backoff doubles with each retryCount', () {
      // retryCount 2 → delay 4000 ms.
      expect(
        policy.shouldRetry(
          _row(
            id: 1,
            retryCount: 2,
            lastAttempt: fakeNow.subtract(const Duration(seconds: 3)),
          ),
        ),
        isFalse,
      );
      expect(
        policy.shouldRetry(
          _row(
            id: 1,
            retryCount: 2,
            lastAttempt: fakeNow.subtract(const Duration(seconds: 5)),
          ),
        ),
        isTrue,
      );
    });
  });
}
