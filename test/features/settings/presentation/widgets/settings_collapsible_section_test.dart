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
  testWidgets('tapping the header toggles collapsed state via onToggle', (
    tester,
  ) async {
    var collapsed = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return _harness(
            SettingsCollapsibleSection(
              title: 'Developer',
              hint: 'Diagnostics and internal tooling',
              icon: Icons.developer_mode_outlined,
              collapsed: collapsed,
              onToggle: () => setState(() => collapsed = !collapsed),
              child: const Text('developer-content'),
            ),
          );
        },
      ),
    );

    expect(find.text('developer-content'), findsNothing);

    await tester.tap(find.text('Developer'));
    await tester.pumpAndSettle();

    expect(find.text('developer-content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an attention badge only while collapsed with an issue', (
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
    expect(find.text(l10n.settingsSectionNeedsAttention), findsOneWidget);
  });

  testWidgets('exposes expand/collapse state via Semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _harness(
        SettingsCollapsibleSection(
          title: 'About',
          hint: 'Version, licenses, and links',
          icon: Icons.info_outline_rounded,
          collapsed: true,
          onToggle: () {},
          child: const Text('about-content'),
        ),
      ),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // The header's Semantics label merges with the title/hint text nodes
    // beneath it, so match as a prefix rather than requiring exact equality.
    expect(
      find.bySemanticsLabel(
        RegExp('^${RegExp.escape(l10n.settingsSectionExpandSemantics)}'),
      ),
      findsOneWidget,
    );

    handle.dispose();
  });
}
