import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';

const _recommended = RecommendedChannel(
  channelId: _channelId,
  name: 'TED',
  handle: '@TED',
  language: 'en',
);

class _FailingDiscoverRepository extends DiscoverRepository {
  _FailingDiscoverRepository(super.db, {required super.libraryRepository});

  @override
  Future<void> subscribeRecommended(RecommendedChannel channel) async {
    throw Exception('subscribe failed');
  }
}

class _BlockingDiscoverRepository extends DiscoverRepository {
  _BlockingDiscoverRepository(
    super.db, {
    required super.libraryRepository,
    required this.gate,
  });

  final Completer<void> gate;

  @override
  Future<void> subscribeRecommended(RecommendedChannel channel) async {
    await gate.future;
  }
}

class _CountingDiscoverRepository extends DiscoverRepository {
  _CountingDiscoverRepository(
    super.db, {
    required super.libraryRepository,
    required this.gate,
  });

  final Completer<void> gate;
  int refreshFeedsCalls = 0;

  @override
  Future<void> subscribeRecommended(RecommendedChannel channel) async {
    await gate.future;
  }

  @override
  Future<DiscoverChannel?> getSubscription(String channelId) async {
    return DiscoverChannel(
      channelId: channelId,
      displayName: 'TED',
      source: YoutubeSubscriptionSource.recommended,
      subscribedAt: DateTime(2026),
    );
  }

  @override
  Future<DiscoverRefreshResult> refreshFeeds({bool force = false}) async {
    refreshFeedsCalls++;
    return const DiscoverRefreshResult(
      refreshedChannels: 0,
      failedChannelIds: [],
    );
  }
}

class _SubscribeHarness extends ConsumerWidget {
  const _SubscribeHarness({required this.channel});

  final RecommendedChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () => subscribeRecommendedChannel(context, ref, channel),
      child: const Text('Subscribe recommended'),
    );
  }
}

/// Mirrors the recommended-avatar strip: the widget that owns the ref is the
/// strip, while the tap handler belongs to a tile inside it and passes the
/// tile's context.
class _StripHarness extends ConsumerStatefulWidget {
  const _StripHarness({super.key, required this.channel});

  final RecommendedChannel channel;

  @override
  ConsumerState<_StripHarness> createState() => _StripHarnessState();
}

class _StripHarnessState extends ConsumerState<_StripHarness> {
  var _tileVisible = true;

  void hideTile() => setState(() => _tileVisible = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_tileVisible)
          Builder(
            builder: (tileContext) => FilledButton(
              onPressed: () => unawaited(
                subscribeRecommendedChannel(tileContext, ref, widget.channel),
              ),
              child: const Text('Subscribe recommended'),
            ),
          ),
      ],
    );
  }
}

Widget _wrap({
  required AppDatabase db,
  required DiscoverRepository repo,
  Widget? home,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      discoverRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home:
          home ??
          const Scaffold(body: _SubscribeHarness(channel: _recommended)),
    ),
  );
}

void main() {
  group('subscribeRecommendedChannel', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('persists subscription and shows success notice', (
      tester,
    ) async {
      final repo = DiscoverRepository(
        db,
        libraryRepository: MediaLibraryRepository(db, FileStorage()),
        httpClient: MockClient((_) async => http.Response('', 404)),
      );

      await tester.pumpWidget(_wrap(db: db, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Subscribe recommended'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
        _channelId,
      );
      expect(row, isNotNull);
      expect(row!.displayName, 'TED');
      expect(row.source, YoutubeSubscriptionSource.recommended);

      expect(find.text('Subscribed to channel'), findsOneWidget);
    });

    testWidgets('shows error notice when subscribe fails', (tester) async {
      final repo = _FailingDiscoverRepository(
        db,
        libraryRepository: MediaLibraryRepository(db, FileStorage()),
      );

      await tester.pumpWidget(_wrap(db: db, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Subscribe recommended'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        await db.youtubeChannelSubscriptionDao.getByChannelId(_channelId),
        isNull,
      );
      expect(find.text('Could not subscribe to that channel.'), findsOneWidget);
    });

    testWidgets(
      'does not read a disposed ref when the screen closes mid-subscribe',
      (tester) async {
        final gate = Completer<void>();
        final repo = _BlockingDiscoverRepository(
          db,
          libraryRepository: MediaLibraryRepository(db, FileStorage()),
          gate: gate,
        );

        await tester.pumpWidget(_wrap(db: db, repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Subscribe recommended'));
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());
        gate.complete();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'still refreshes the feed when the tapped tile is removed mid-subscribe',
      (tester) async {
        final gate = Completer<void>();
        final repo = _CountingDiscoverRepository(
          db,
          libraryRepository: MediaLibraryRepository(db, FileStorage()),
          gate: gate,
        );
        final harnessKey = GlobalKey<_StripHarnessState>();

        await tester.pumpWidget(
          _wrap(
            db: db,
            repo: repo,
            home: Scaffold(
              body: _StripHarness(key: harnessKey, channel: _recommended),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Subscribe recommended'));
        await tester.pump();

        harnessKey.currentState!.hideTile();
        await tester.pump();

        gate.complete();
        await tester.pumpAndSettle();

        expect(repo.refreshFeedsCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
