import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(Brightness.dark),
  home: Scaffold(body: Center(child: child)),
);

Container _badgeContainer(WidgetTester tester) => tester.widget<Container>(
  find
      .descendant(
        of: find.byType(EnjoyTierBadge),
        matching: find.byType(Container),
      )
      .first,
);

EnjoyThemeTokens _tokens(WidgetTester tester) =>
    EnjoyThemeTokens.of(tester.element(find.byType(EnjoyTierBadge)));

void main() {
  testWidgets('default badge rides the aurora with compact padding', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const EnjoyTierBadge(label: 'Pro')));
    await tester.pumpAndSettle();

    final t = _tokens(tester);
    final container = _badgeContainer(tester);
    expect(
      container.padding,
      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
    );
    final decoration = container.decoration as ShapeDecoration;
    expect(decoration.shape, const StadiumBorder());
    expect(decoration.gradient, t.aurora);
    expect(decoration.color, isNull);

    final text = tester.widget<Text>(find.text('Pro'));
    expect(text.style?.color, Colors.white);
    expect(text.style?.fontSize, 10.5);
    expect(text.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('muted badge swaps the aurora for a neutral fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EnjoyTierBadge(label: 'Lite', muted: true)),
    );
    await tester.pumpAndSettle();

    final t = _tokens(tester);
    final decoration = _badgeContainer(tester).decoration as ShapeDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, t.fill);
    expect(tester.widget<Text>(find.text('Lite')).style?.color, isNotNull);
  });

  testWidgets('leading icon rides the label color', (tester) async {
    await tester.pumpWidget(
      _host(
        const EnjoyTierBadge(
          label: 'Recommended',
          leading: EnjoyIcons.sparkleFill,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(EnjoyIcons.sparkleFill));
    expect(icon.size, 12);
    expect(icon.color, Colors.white);
  });

  testWidgets('padding override and solid color drop the aurora', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const EnjoyTierBadge(
          label: 'Current plan',
          color: Color(0xFF3A2E55),
          textColor: Color(0xFFEDE7FF),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = _badgeContainer(tester);
    expect(
      container.padding,
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
    final decoration = container.decoration as ShapeDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, const Color(0xFF3A2E55));
    expect(
      tester.widget<Text>(find.text('Current plan')).style?.color,
      const Color(0xFFEDE7FF),
    );
  });

  testWidgets('shape override replaces the stadium pill', (tester) async {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    );
    await tester.pumpWidget(
      _host(const EnjoyTierBadge(label: 'Pro', shape: shape)),
    );
    await tester.pumpAndSettle();

    final decoration = _badgeContainer(tester).decoration as ShapeDecoration;
    expect(decoration.shape, shape);
    expect(decoration.gradient, _tokens(tester).aurora);
  });
}
