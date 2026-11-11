import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/features/craft/application/craft_history_provider.dart';
import 'package:enjoy_player/features/craft/presentation/craft_history_screen.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Media _craftMedia({
  required String id,
  required String title,
  required DateTime updatedAt,
}) {
  return Media(
    id: id,
    kind: MediaKind.audio,
    title: title,
    sourceUri: 'file:///$id.wav',
    durationMs: 1000,
    language: 'en-US',
    contentHash: id,
    fileSize: 10,
    provider: 'craft',
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}

Widget _harness({required List<Media> items}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  final router = GoRouter(
    initialLocation: '/craft/history',
    routes: [
      GoRoute(path: '/craft', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/craft/history',
        builder: (_, _) => const CraftHistoryScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      craftHistoryProvider.overrideWith((ref) => Stream.value(items)),
    ],
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CraftHistoryScreen shows empty state when no Craft items', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(items: const []));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.craftHistoryEmptyTitle), findsOneWidget);
    expect(find.text(l10n.craftHistoryEmptyAction), findsOneWidget);
  });

  testWidgets('CraftHistoryScreen lists Craft items by title', (tester) async {
    final newer = DateTime.utc(2026, 7, 23, 12);
    final older = DateTime.utc(2026, 7, 22, 12);
    await tester.pumpWidget(
      _harness(
        items: [
          _craftMedia(id: 'a', title: 'Newer craft line', updatedAt: newer),
          _craftMedia(id: 'b', title: 'Older craft line', updatedAt: older),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Newer craft line'), findsOneWidget);
    expect(find.text('Older craft line'), findsOneWidget);
  });

  testWidgets(
    'CraftHistoryScreen subtitles each row with the tile date format',
    (tester) async {
      final times = [
        DateTime.utc(2026, 7, 23, 12, 30),
        DateTime.utc(2025, 1, 5, 8, 5),
      ];
      await tester.pumpWidget(
        _harness(
          items: [
            _craftMedia(
              id: 'a',
              title: 'Subtitle oracle one',
              updatedAt: times[0],
            ),
            _craftMedia(
              id: 'b',
              title: 'Subtitle oracle two',
              updatedAt: times[1],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final subtitles = [
        for (final time in times)
          DateFormat.yMMMd().add_jm().format(time.toLocal()),
      ];
      expect(find.text(subtitles[0]), findsOneWidget);
      expect(find.text(subtitles[1]), findsOneWidget);
    },
  );

  testWidgets(
    'CraftHistoryScreen groups rows in one inset card under a header',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          items: [
            _craftMedia(
              id: 'a',
              title: 'First craft',
              updatedAt: DateTime.utc(2026, 7, 23, 12),
            ),
            _craftMedia(
              id: 'b',
              title: 'Second craft',
              updatedAt: DateTime.utc(2026, 7, 22, 12),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byType(EnjoySectionHeader), findsOneWidget);
      expect(find.text(l10n.craftHistoryTitle), findsWidgets);
      expect(find.byType(EnjoyCard), findsOneWidget);
      expect(find.byType(SettingsRow), findsNWidgets(2));
      expect(find.byType(SettingsRowDivider), findsOneWidget);
      expect(find.byType(EnjoyIconTile), findsNWidgets(2));
    },
  );

  testWidgets('CraftHistoryScreen remove control opens confirm dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        items: [
          _craftMedia(
            id: 'a',
            title: 'Removable craft',
            updatedAt: DateTime.utc(2026, 7, 23, 12),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.byTooltip(l10n.craftHistoryRemoveTooltip));
    await tester.pumpAndSettle();

    expect(find.text(l10n.craftHistoryRemoveTitle), findsOneWidget);
    expect(
      find.text(l10n.craftHistoryRemoveMessage('Removable craft')),
      findsOneWidget,
    );
  });
}
