import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/craft/application/craft_history_provider.dart';
import 'package:enjoy_player/features/craft/presentation/craft_history_screen.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
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
}
