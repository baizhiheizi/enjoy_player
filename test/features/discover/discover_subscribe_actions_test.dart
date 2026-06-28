import 'package:drift/native.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
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
  _FailingDiscoverRepository(super.db);

  @override
  Future<void> subscribeRecommended(RecommendedChannel channel) async {
    throw Exception('subscribe failed');
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

Widget _wrap({required AppDatabase db, required DiscoverRepository repo}) {
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
      home: const Scaffold(body: _SubscribeHarness(channel: _recommended)),
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
      expect(row.source, 'recommended');

      expect(find.text('Subscribed to channel'), findsOneWidget);
    });

    testWidgets('shows error notice when subscribe fails', (tester) async {
      final repo = _FailingDiscoverRepository(db);

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
  });
}
