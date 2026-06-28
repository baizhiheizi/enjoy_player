import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

SyncQueueRow _row({
  required int id,
  int retryCount = 0,
  DateTime? lastAttempt,
}) {
  return SyncQueueRow(
    id: id,
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
  group('shouldRetryQueueItem', () {
    test('allows first attempt when lastAttempt is null', () {
      expect(shouldRetryQueueItem(_row(id: 1)), isTrue);
    });

    test('blocks permanently failed rows (retryCount >= 5)', () {
      expect(
        shouldRetryQueueItem(_row(id: 1, retryCount: 5)),
        isFalse,
      );
    });

    test('applies exponential backoff from lastAttempt', () {
      final now = DateTime.now();
      // retryCount 1 → delay 2000 ms
      expect(
        shouldRetryQueueItem(
          _row(id: 1, retryCount: 1, lastAttempt: now),
        ),
        isFalse,
      );
      expect(
        shouldRetryQueueItem(
          _row(
            id: 1,
            retryCount: 1,
            lastAttempt: now.subtract(const Duration(seconds: 3)),
          ),
        ),
        isTrue,
      );
    });

    test('backoff doubles with each retryCount', () {
      final now = DateTime.now();
      // retryCount 2 → delay 4000 ms
      expect(
        shouldRetryQueueItem(
          _row(
            id: 1,
            retryCount: 2,
            lastAttempt: now.subtract(const Duration(seconds: 3)),
          ),
        ),
        isFalse,
      );
      expect(
        shouldRetryQueueItem(
          _row(
            id: 1,
            retryCount: 2,
            lastAttempt: now.subtract(const Duration(seconds: 5)),
          ),
        ),
        isTrue,
      );
    });
  });
}
