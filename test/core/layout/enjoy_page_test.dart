import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_subpage_app_bar.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: buildAppTheme(), home: child);
  }

  testWidgets('pageGutterOf uses compact gutter below breakpointCompact', (
    tester,
  ) async {
    late double gutter;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            gutter = pageGutterOf(context, 500);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final t = EnjoyThemeTokens.build(
      ThemeData(brightness: Brightness.dark).colorScheme,
    );
    expect(gutter, t.pageGutterCompact);
  });

  testWidgets('pageGutterOf uses default gutter at/above breakpointCompact', (
    tester,
  ) async {
    late double gutter;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            gutter = pageGutterOf(context, 800);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final tokens = EnjoyThemeTokens.of(
      tester.element(find.byType(SizedBox).first),
    );
    expect(gutter, tokens.pageGutter);
  });

  testWidgets('form EnjoyPage centers content with formMaxWidth insets', (
    tester,
  ) async {
    late EnjoyPageMetrics metrics;
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        EnjoyPage(
          kind: EnjoyPageKind.form,
          title: 'Preferences',
          showBack: true,
          body: (context, m) {
            metrics = m;
            return Text('body-${m.horizontalInset}');
          },
        ),
      ),
    );

    expect(find.byType(EnjoySubpageAppBar), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    final tokens = EnjoyThemeTokens.of(
      tester.element(find.textContaining('body-')),
    );
    expect(metrics.kind, EnjoyPageKind.form);
    expect(metrics.maxWidth, tokens.formMaxWidth);
    expect(
      metrics.horizontalInset,
      closeTo((1400 - tokens.formMaxWidth) / 2, 0.5),
    );
  });

  testWidgets('browse EnjoyPage uses gutter-only horizontal inset', (
    tester,
  ) async {
    late EnjoyPageMetrics metrics;
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        EnjoyPage(
          kind: EnjoyPageKind.browse,
          body: (context, m) {
            metrics = m;
            return const Text('browse');
          },
        ),
      ),
    );

    final tokens = EnjoyThemeTokens.of(tester.element(find.text('browse')));
    expect(metrics.maxWidth, isNull);
    expect(metrics.horizontalInset, tokens.pageGutter);
    expect(find.byType(EnjoySubpageAppBar), findsNothing);
  });

  test('maxWidthForPageKind maps families', () {
    final tokens = EnjoyThemeTokens.build(
      ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.dark,
      ),
    );
    expect(maxWidthForPageKind(tokens, EnjoyPageKind.browse), isNull);
    expect(maxWidthForPageKind(tokens, EnjoyPageKind.hub), tokens.hubMaxWidth);
    expect(
      maxWidthForPageKind(tokens, EnjoyPageKind.form),
      tokens.formMaxWidth,
    );
    expect(
      maxWidthForPageKind(tokens, EnjoyPageKind.auth),
      tokens.modalMaxWidth,
    );
  });
}
