import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [DiscoverRepository] that delays and records each [refreshFeeds] call.
class _TestDiscoverRepository extends DiscoverRepository {
  _TestDiscoverRepository(super.db);

  /// Completer that stalls the first [refreshFeeds] until released.
  final barrier = Completer<void>();

  /// Number of times [refreshFeeds] has been entered (not completed).
  int refreshCallCount = 0;

  /// Number of times [refreshFeeds] has completed.
  int refreshCompleteCount = 0;

  @override
  Future<DiscoverRefreshResult> refreshFeeds({bool force = false}) async {
    refreshCallCount++;
    try {
      return await super.refreshFeeds(force: force);
    } finally {
      await barrier.future;
      refreshCompleteCount++;
    }
  }
}

void main() {
  group('DiscoverRefreshState single-flight', () {
    late AppDatabase db;
    late _TestDiscoverRepository repo;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = _TestDiscoverRepository(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          discoverRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('concurrent refresh calls are deduped to a single in-flight', () async {
      final notifier = container.read(discoverRefreshStateProvider.notifier);

      // Launch the first refresh — it will stall at the barrier.
      final firstFuture = notifier.refresh();
      // Yield so the provider's async function enters refreshFeeds.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // While the first is still in-flight, launch a second.
      final secondFuture = notifier.refresh();

      // Not yet complete: only one refreshFeeds call should have started.
      expect(repo.refreshCallCount, 1,
          reason: 'only one refreshFeeds call should have been initiated');

      // Release the barrier so the first (and only) refreshFeeds completes.
      repo.barrier.complete();

      // Both futures should resolve — they share the same underlying result.
      final firstResult = await firstFuture;
      final secondResult = await secondFuture;

      expect(firstResult, same(secondResult),
          reason: 'both callers should receive the identical result object');
      expect(repo.refreshCompleteCount, 1,
          reason: 'refreshFeeds should have completed exactly once');
    });

    test('subsequent refresh works after in-flight completes', () async {
      final notifier = container.read(discoverRefreshStateProvider.notifier);

      // First call: release barrier immediately.
      repo.barrier.complete();
      await notifier.refresh();
      expect(repo.refreshCompleteCount, 1);

      // Second call should proceed normally (no in-flight guard active).
      // Re-arm the barrier so we can observe the second call is independent.
      final secondBarrier = Completer<void>();
      repo.barrier = secondBarrier;
      final secondFuture = notifier.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCallCount, 2,
          reason: 'a second refreshFeeds should start after the first completed');
      secondBarrier.complete();
      await secondFuture;
      expect(repo.refreshCompleteCount, 2);
    });
  });
}
