import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_manage_channels.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

final _recommended = [
  const RecommendedChannel(
    channelId: 'UC_rec_001',
    name: 'BBC Learning English',
    handle: '@BBCLearningEnglish',
    language: 'en',
  ),
  const RecommendedChannel(
    channelId: 'UC_rec_002',
    name: 'Deutsch mit Marija',
    handle: '@DeutschMitMarija',
    language: 'de',
  ),
];

final _subscriptions = [
  DiscoverChannel(
    channelId: 'UC_sub_001',
    displayName: 'TED',
    source: YoutubeSubscriptionSource.recommended,
    subscribedAt: DateTime.utc(2024, 1, 1),
  ),
];

Widget _wrap(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides:
        overrides ??
        [
          filteredRecommendedChannelsProvider.overrideWith(
            (ref) => _recommended,
          ),
          discoverSubscriptionsProvider.overrideWith(
            (ref) => Stream.value(_subscriptions),
          ),
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

void main() {
  group('DiscoverManageChannelsView (dialog presentation)', () {
    testWidgets('renders title, recommended heading, and subscriptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DiscoverManageChannelsView(
            presentation: DiscoverManageChannelsPresentation.dialog,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dialog title
      expect(find.text('Manage channels'), findsOneWidget);

      // Recommended section heading
      expect(find.text('Recommended'), findsOneWidget);

      // Subscribe action button
      expect(find.text('Subscribe'), findsOneWidget);

      // Your channels heading
      expect(find.text('Your channels'), findsOneWidget);

      // Subscription row shows channel name
      expect(find.text('TED'), findsOneWidget);

      // Close button present in dialog mode
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('shows empty state when no subscriptions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DiscoverManageChannelsView(
            presentation: DiscoverManageChannelsPresentation.dialog,
          ),
          overrides: [
            filteredRecommendedChannelsProvider.overrideWith(
              (ref) => _recommended,
            ),
            discoverSubscriptionsProvider.overrideWith(
              (ref) => Stream.value(<DiscoverChannel>[]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Empty hint text
      expect(
        find.text('Subscribe to a recommended channel or paste a channel URL.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error text when recommended fails', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DiscoverManageChannelsView(
            presentation: DiscoverManageChannelsPresentation.dialog,
          ),
          overrides: [
            filteredRecommendedChannelsProvider.overrideWith(
              (ref) =>
                  Future<List<RecommendedChannel>>.error(Exception('network')),
            ),
            discoverSubscriptionsProvider.overrideWith(
              (ref) => Stream.value(_subscriptions),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load recommended channels.'), findsOneWidget);
    });

    testWidgets('shows error text when subscriptions fail', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DiscoverManageChannelsView(
            presentation: DiscoverManageChannelsPresentation.dialog,
          ),
          overrides: [
            filteredRecommendedChannelsProvider.overrideWith(
              (ref) => _recommended,
            ),
            discoverSubscriptionsProvider.overrideWith(
              (ref) =>
                  Stream<List<DiscoverChannel>>.error(Exception('db error')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load subscriptions.'), findsOneWidget);
    });
  });

  group('DiscoverManageChannelsView (sheet presentation)', () {
    testWidgets('renders sheet layout with drag handle and title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DiscoverManageChannelsView(
            presentation: DiscoverManageChannelsPresentation.sheet,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sheet title
      expect(find.text('Manage channels'), findsOneWidget);

      // Recommended heading
      expect(find.text('Recommended'), findsOneWidget);

      // Your channels heading
      expect(find.text('Your channels'), findsOneWidget);
    });
  });
}
