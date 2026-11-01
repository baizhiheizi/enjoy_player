import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_pill_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<EnjoyThemeTokens> _pump(WidgetTester tester, Widget child) async {
  final theme = buildAppTheme(Brightness.light);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  return theme.extension<EnjoyThemeTokens>()!;
}

void main() {
  testWidgets('default badge renders the quiet treatment on sunk', (
    tester,
  ) async {
    final t = await _pump(tester, const EnjoyPillBadge(label: 'Allowed'));

    final box = tester.widget<Container>(find.byType(Container));
    expect((box.decoration! as ShapeDecoration).color, t.sunk);
    expect(tester.widget<Text>(find.byType(Text)).data, 'Allowed');
  });

  testWidgets('default badge labels in ink2', (tester) async {
    final t = await _pump(tester, const EnjoyPillBadge(label: 'Allowed'));

    expect(tester.widget<Text>(find.byType(Text)).style?.color, t.ink2);
  });

  testWidgets('emphasized badge renders the ink fill with a paper label', (
    tester,
  ) async {
    final t = await _pump(
      tester,
      const EnjoyPillBadge(label: 'Denied', emphasized: true),
    );

    final box = tester.widget<Container>(find.byType(Container));
    expect((box.decoration! as ShapeDecoration).color, t.ink);
    expect(tester.widget<Text>(find.byType(Text)).style?.color, t.paper);
  });

  testWidgets('badge is a 24px stadium with 10px horizontal padding', (
    tester,
  ) async {
    await _pump(tester, const EnjoyPillBadge(label: 'Auto-renew on'));

    final box = tester.widget<Container>(find.byType(Container));
    expect(box.constraints?.minHeight, 24);
    expect(box.constraints?.maxHeight, 24);
    expect(box.padding, const EdgeInsets.symmetric(horizontal: 10));
    expect((box.decoration! as ShapeDecoration).shape, isA<StadiumBorder>());
  });

  testWidgets('badge fits its label instead of the width its parent offers', (
    tester,
  ) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: const Align(
            alignment: Alignment.centerRight,
            child: EnjoyPillBadge(label: 'Allowed'),
          ),
        ),
      ),
    );

    final badgeWidth = tester.getSize(find.byType(EnjoyPillBadge)).width;
    final labelWidth = tester.getSize(find.byType(Text)).width;
    expect(badgeWidth, closeTo(labelWidth + 20, 0.01));
  });

  testWidgets('fillWidth badge fills the width its parent offers', (
    tester,
  ) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: const EnjoyPillBadge(label: 'Allowed', fillWidth: true),
        ),
      ),
    );

    expect(tester.getSize(find.byType(EnjoyPillBadge)).width, 300);
  });
}
