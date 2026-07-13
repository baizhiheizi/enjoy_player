import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_collapsible_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Widget _harness(Widget child) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders content always visible (no collapse header)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        SettingsCollapsibleSection(
          title: 'Developer',
          hint: 'Diagnostics and internal tooling',
          icon: Icons.developer_mode_outlined,
          collapsed: true,
          onToggle: () {},
          child: const Text('developer-content'),
        ),
      ),
    );

    expect(find.text('developer-content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without attention badge (header removed)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        SettingsCollapsibleSection(
          title: 'Developer',
          hint: 'Diagnostics and internal tooling',
          icon: Icons.developer_mode_outlined,
          collapsed: true,
          needsAttention: true,
          onToggle: () {},
          child: const Text('developer-content'),
        ),
      ),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.settingsSectionNeedsAttention), findsNothing);
    expect(find.text('developer-content'), findsOneWidget);
  });

  testWidgets('always shows child regardless of collapsed state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        SettingsCollapsibleSection(
          title: 'About',
          hint: 'Version, licenses, and links',
          icon: Icons.info_outline_rounded,
          collapsed: false,
          onToggle: () {},
          child: const Text('about-content'),
        ),
      ),
    );

    expect(find.text('about-content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
