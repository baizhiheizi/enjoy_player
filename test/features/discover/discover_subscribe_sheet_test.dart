import 'package:drift/native.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
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
  await tester.pumpAndSettle();
}

void main() {
  group('showDiscoverSubscribeSheet', () {
    late AppDatabase db;
    late DiscoverRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = DiscoverRepository(
        db,
        httpClient: MockClient((_) async => http.Response('', 404)),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'opens scroll-controlled sheet with input and subscribe action',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            db: db,
            repo: repo,
            onOpenSheet: () => showDiscoverSubscribeSheet(
              tester.element(find.text('Open sheet')),
            ),
          ),
        );

        await _openSheet(tester);

        expect(find.text('Subscribe to channel'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text('Subscribe'), findsOneWidget);
      },
    );

    testWidgets('rebuilds safely when keyboard viewInsets change while open', (
      tester,
    ) async {
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          db: db,
          repo: repo,
          onOpenSheet: () => showDiscoverSubscribeSheet(
            tester.element(find.text('Open sheet')),
          ),
        ),
      );
      await _openSheet(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'dismiss via drag after keyboard inset changes does not throw',
      (tester) async {
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            db: db,
            repo: repo,
            onOpenSheet: () => showDiscoverSubscribeSheet(
              tester.element(find.text('Open sheet')),
            ),
          ),
        );
        await _openSheet(tester);

        await tester.enterText(find.byType(TextField), _channelId);

        tester.view.viewInsets = const FakeViewPadding(bottom: 336);
        await tester.pump();

        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pump();

        await tester.drag(find.byType(BottomSheet), const Offset(0, 500));
        await tester.pumpAndSettle();

        expect(find.text('Subscribe to channel'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('submit with channel id subscribes and closes sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          db: db,
          repo: repo,
          onOpenSheet: () => showDiscoverSubscribeSheet(
            tester.element(find.text('Open sheet')),
          ),
        ),
      );
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), _channelId);
      await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Subscribe to channel'), findsNothing);

      final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
        _channelId,
      );
      expect(row, isNotNull);
      expect(row!.source, 'user');
    });
  });
}
