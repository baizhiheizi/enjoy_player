import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
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
  for (final tone in EnjoyIconTileTone.values) {
    testWidgets('icon tile $tone uses a soft fill and an ink glyph', (
      tester,
    ) async {
      final t = await _pump(
        tester,
        EnjoyIconTile(icon: EnjoyIcons.settings, tone: tone),
      );
      final (fill, ink) = switch (tone) {
        EnjoyIconTileTone.neutral => (t.sunk, t.ink2),
        EnjoyIconTileTone.brand => (t.brandSoft, t.brandInk),
        EnjoyIconTileTone.original => (t.originalSoft, t.originalInk),
      };
      final box = tester.widget<Container>(find.byType(Container));
      expect((box.decoration! as ShapeDecoration).color, fill);
      expect(tester.widget<Icon>(find.byType(Icon)).color, ink);
    });
  }

  testWidgets('disabled icon tile drops to ink3', (tester) async {
    final t = await _pump(
      tester,
      const EnjoyIconTile(
        icon: EnjoyIcons.settings,
        tone: EnjoyIconTileTone.brand,
        enabled: false,
      ),
    );
    expect(tester.widget<Icon>(find.byType(Icon)).color, t.ink3);
  });

  testWidgets('segment count renders after the label in ink3', (tester) async {
    final t = await _pump(
      tester,
      EnjoySegmentedControl<int>(
        segments: const [
          EnjoySegment(value: 0, label: 'Video', count: 9),
          EnjoySegment(value: 1, label: 'Audio', count: 7),
        ],
        value: 0,
        onChanged: (_) {},
      ),
    );
    expect(find.text('9'), findsOneWidget);
    expect(tester.widget<Text>(find.text('7')).style?.color, t.ink3);
  });
}
