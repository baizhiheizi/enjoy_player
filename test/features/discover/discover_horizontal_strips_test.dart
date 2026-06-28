import 'package:enjoy_player/core/interaction/horizontal_drag_scroll_behavior.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_filter_strip.dart';
import 'package:enjoy_player/features/discover/presentation/discover_recommended_avatar_strip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';

const _recommended = [
  RecommendedChannel(
    channelId: _channelId,
    name: 'TED',
    handle: '@TED',
    language: 'en',
  ),
  RecommendedChannel(
    channelId: 'UCtestchannel0002',
    name: 'BBC',
    handle: '@BBC',
    language: 'en',
  ),
];

Widget _localized(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
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

Finder _horizontalDragScrollConfiguration() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ScrollConfiguration &&
        widget.behavior is HorizontalDragScrollBehavior,
  );
}

void main() {
  group('Discover horizontal strips', () {
    testWidgets(
      'recommended avatar strip uses stable horizontal scroll behavior',
      (tester) async {
        await tester.pumpWidget(
          _localized(
            const DiscoverRecommendedAvatarStrip(
              recommended: _recommended,
              subscribedChannelIds: {},
            ),
            overrides: [
              for (final channel in _recommended)
                recommendedChannelAvatarProvider(
                  channel.channelId,
                ).overrideWith((ref) async => null),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(_horizontalDragScrollConfiguration(), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets('channel filter strip uses stable horizontal scroll behavior', (
      tester,
    ) async {
      final subscribedAt = DateTime.utc(2024, 1, 1);
      final subs = [
        DiscoverChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          subscribedAt: subscribedAt,
        ),
      ];

      await tester.pumpWidget(
        _localized(
          const DiscoverChannelFilterStrip(),
          overrides: [
            discoverSubscriptionsProvider.overrideWith(
              (ref) => Stream.value(subs),
            ),
            recommendedChannelAvatarProvider(
              _channelId,
            ).overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_horizontalDragScrollConfiguration(), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets(
      'recommended avatar strip rebuilds when subscription set changes',
      (tester) async {
        await tester.pumpWidget(
          _localized(
            const DiscoverRecommendedAvatarStrip(
              recommended: _recommended,
              subscribedChannelIds: {},
            ),
            overrides: [
              for (final channel in _recommended)
                recommendedChannelAvatarProvider(
                  channel.channelId,
                ).overrideWith((ref) async => null),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        expect(_horizontalDragScrollConfiguration(), findsOneWidget);

        await tester.pumpWidget(
          _localized(
            const DiscoverRecommendedAvatarStrip(
              recommended: _recommended,
              subscribedChannelIds: {_channelId},
            ),
            overrides: [
              for (final channel in _recommended)
                recommendedChannelAvatarProvider(
                  channel.channelId,
                ).overrideWith((ref) async => null),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_horizontalDragScrollConfiguration(), findsOneWidget);
      },
    );
  });
}
