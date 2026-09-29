import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [DiscoverRepository] that stalls [refreshFeeds] until [barrier] completes.
class _TestDiscoverRepository extends DiscoverRepository {
  _TestDiscoverRepository(super.db, {required super.libraryRepository});

  /// Completer that stalls [refreshFeeds] until released.
  Completer<void> barrier = Completer<void>();

  /// Number of times [refreshFeeds] has been entered (not completed).
  int refreshCallCount = 0;

  /// Number of times [refreshFeeds] has completed.
  int refreshCompleteCount = 0;

  @override
  Future<DiscoverRefreshResult> refreshFeeds({bool force = false}) async {
    refreshCallCount++;
    await barrier.future;
    refreshCompleteCount++;
    return const DiscoverRefreshResult(
      refreshedChannels: 0,
      failedChannelIds: [],
    );
  }
}

void main() {
  group('DiscoverRefreshState single-flight', () {
    late AppDatabase db;
    late _TestDiscoverRepository repo;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = _TestDiscoverRepository(
        db,
        libraryRepository: MediaLibraryRepository(db, FileStorage()),
      );
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

    test(
      'concurrent refresh calls are deduped to a single in-flight',
      () async {
        final notifier = container.read(discoverRefreshStateProvider.notifier);

        final firstFuture = notifier.refresh();
        await Future<void>.delayed(Duration.zero);

        final secondFuture = notifier.refresh();

        expect(
          repo.refreshCallCount,
          1,
          reason: 'only one refreshFeeds call should have been initiated',
        );

        repo.barrier.complete();

        final firstResult = await firstFuture;
        final secondResult = await secondFuture;

        expect(
          firstResult,
          same(secondResult),
          reason: 'both callers should receive the identical result object',
        );
        expect(
          repo.refreshCompleteCount,
          1,
          reason: 'refreshFeeds should have completed exactly once',
        );
      },
    );

    test('subsequent refresh works after in-flight completes', () async {
      final notifier = container.read(discoverRefreshStateProvider.notifier);

      repo.barrier.complete();
      await notifier.refresh();
      expect(repo.refreshCompleteCount, 1);

      final secondBarrier = Completer<void>();
      repo.barrier = secondBarrier;
      final secondFuture = notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(
        repo.refreshCallCount,
        2,
        reason: 'a second refreshFeeds should start after the first completed',
      );
      secondBarrier.complete();
      await secondFuture;
      expect(repo.refreshCompleteCount, 2);
    });
  });
}
