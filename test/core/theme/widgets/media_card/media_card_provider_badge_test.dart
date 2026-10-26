import 'package:enjoy_player/core/theme/widgets/media_card/media_card_provider_badge.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('maps each known provider to its localized badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox()),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)))!;
    expect(resolveMediaCardProviderBadge(l10n, 'youtube'), l10n.youtubeBadge);
    expect(
      resolveMediaCardProviderBadge(l10n, 'craft'),
      l10n.libraryProviderCraftBadge,
    );
    expect(resolveMediaCardProviderBadge(l10n, 'local'), isNull);
  });
}
