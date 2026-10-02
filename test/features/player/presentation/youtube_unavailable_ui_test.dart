import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_widgets.dart';
import 'package:enjoy_player/features/player/presentation/youtube_login_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Widget> host(Widget child) async {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(child: child),
    );
  }

  group('ExpandedPlayerYoutubeUnavailableBody (specs/047 US2)', () {
    testWidgets(
      'shows the localized notice and the browser fallback when the URL is known',
      (tester) async {
        await tester.pumpWidget(
          await host(
            ExpandedPlayerYoutubeUnavailableBody(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              youtubeUrl: 'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
            ),
          ),
        );
        await tester.pump();

        final context = tester.element(find.byType(Scaffold).first);
        final l10n = AppLocalizations.of(context)!;
        expect(find.text(l10n.youtubeUnavailableOnDevice), findsOneWidget);
        expect(find.text(l10n.youtubeOpenInBrowser), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('omits the browser fallback when the video URL is unknown', (
      tester,
    ) async {
      await tester.pumpWidget(
        await host(
          ExpandedPlayerYoutubeUnavailableBody(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.youtubeUnavailableOnDevice), findsOneWidget);
      expect(find.text(l10n.youtubeOpenInBrowser), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('YoutubeLoginScreen availability gate (specs/047 FR-007)', () {
    testWidgets('shows the unavailable notice instead of the sign-in WebView', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProviderScope(
            overrides: [
              youtubeAvailabilityProvider.overrideWith(
                (ref) async => const YouTubeUnavailable(
                  YouTubeUnavailableReason.runtimeMissing,
                ),
              ),
            ],
            child: const YoutubeLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.youtubeUnavailableOnDevice), findsOneWidget);
      expect(find.byType(YoutubeLoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
