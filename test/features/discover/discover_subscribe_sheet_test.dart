import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/presentation/discover_subscribe_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';

String _validJsonFeed({String channelId = _channelId}) => jsonEncode({
  'version': 'https://jsonfeed.org/version/1.1',
  'title': 'Test Channel - YouTube',
  'home_page_url': 'https://www.youtube.com/channel/$channelId',
  'items': [
    {
      'id': 'https://www.youtube.com/watch?v=test1234567',
      'url': 'https://www.youtube.com/watch?v=test1234567',
      'title': 'Test Video',
      'date_published': '2026-07-10T08:00:00.000Z',
    },
  ],
});

Widget _wrap({
  required AppDatabase db,
  required DiscoverRepository repo,
  required VoidCallback onOpenSheet,
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
      home: Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: onOpenSheet,
            child: const Text('Open sheet'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open sheet'));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Finds the subscribe sheet by looking for the title text.
Widget _findSubscribeSheetTitle(WidgetTester tester) {
  return find.textContaining('Subscribe to').evaluate().first.widget as Text;
}

void main() {
  group('showDiscoverSubscribeSheet', () {
    late AppDatabase db;
    late DiscoverRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('?format=json')) {
            return http.Response(_validJsonFeed(), 200);
          }
          return http.Response('', 404);
        }),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('opens scroll-controlled sheet with input and subscribe action',
      (tester) async {
        await tester.pumpWidget(_wrap(
          db: db,
          repo: repo,
          onOpenSheet: () => showDiscoverSubscribeSheet(
            tester.element(find.text('Open sheet')),
          ),
        ));
        await _openSheet(tester);

        expect(find.text('Subscribe to channel'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text('Subscribe'), findsOneWidget);
      },
    );

    testWidgets('subscribe with valid channel id creates subscription',
      (tester) async {
        await tester.pumpWidget(_wrap(
          db: db,
          repo: repo,
          onOpenSheet: () => showDiscoverSubscribeSheet(
            tester.element(find.text('Open sheet')),
          ),
        ));
        await _openSheet(tester);

        await tester.enterText(find.byType(TextField), _channelId);
        await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        // Verify subscription in DB
        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row, isNotNull);
        expect(row!.source, YoutubeSubscriptionSource.user);
        expect(row.sourceType, YoutubeSourceType.channel);
        expect(row.feedUrl, isNotNull);

        // Verify feed entries cached
        final entries = await db.youtubeFeedEntryDao.watchForChannel(
          _channelId,
        ).first;
        expect(entries.length, 1);
        expect(entries.first.videoId, 'test1234567');
      },
    );

    testWidgets('subscribe with invalid URL shows error', (tester) async {
      await tester.pumpWidget(_wrap(
        db: db,
        repo: repo,
        onOpenSheet: () => showDiscoverSubscribeSheet(
          tester.element(find.text('Open sheet')),
        ),
      ));
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'not a url');
      await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Should show error (no subscription created)
      final subs = await db.youtubeChannelSubscriptionDao.listAll();
      expect(subs, isEmpty);
    });
  });
}
