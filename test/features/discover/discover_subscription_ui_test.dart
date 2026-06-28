import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_recommended_channel_card.dart';
import 'package:enjoy_player/features/discover/presentation/discover_subscription_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final subscribedAt = DateTime.utc(2024, 1, 1);

  final subscribedChannel = DiscoverChannel(
    channelId: 'UCtestchannel0001',
    displayName: 'TED',
    source: YoutubeSubscriptionSource.recommended,
    subscribedAt: subscribedAt,
  );

  const recommended = RecommendedChannel(
    channelId: 'UCtestchannel0001',
    name: 'TED',
    handle: '@TED',
    language: 'en',
  );

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        recommendedChannelAvatarProvider(
          'UCtestchannel0001',
        ).overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  group('DiscoverSubscriptionRow', () {
    testWidgets('tap row navigates to channel feed', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => DiscoverSubscriptionRow(
              channel: subscribedChannel,
              onUnsubscribe: () {},
            ),
          ),
          GoRoute(
            path: '/discover/channel/:channelId',
            builder: (_, state) =>
                Text('feed:${state.pathParameters['channelId']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recommendedChannelAvatarProvider(
              'UCtestchannel0001',
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TED'));
      await tester.pumpAndSettle();

      expect(find.text('feed:UCtestchannel0001'), findsOneWidget);
    });

    testWidgets('Unsubscribe button calls handler without navigating', (
      tester,
    ) async {
      var unsubscribed = false;

      await tester.pumpWidget(
        wrap(
          DiscoverSubscriptionRow(
            channel: subscribedChannel,
            onUnsubscribe: () => unsubscribed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unsubscribe'));
      await tester.pumpAndSettle();

      expect(unsubscribed, isTrue);
    });
  });

  group('DiscoverRecommendedChannelCard', () {
    testWidgets('subscribed shows badge without Subscribe button', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DiscoverRecommendedChannelCard(
            channel: recommended,
            subscribed: true,
            onSubscribe: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscribed'), findsOneWidget);
      expect(find.text('Subscribe'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('not subscribed shows Subscribe button', (tester) async {
      var subscribed = false;

      await tester.pumpWidget(
        wrap(
          DiscoverRecommendedChannelCard(
            channel: recommended,
            subscribed: false,
            onSubscribe: () => subscribed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscribe'), findsOneWidget);
      expect(find.text('Subscribed'), findsNothing);

      await tester.tap(find.text('Subscribe'));
      expect(subscribed, isTrue);
    });
  });
}
