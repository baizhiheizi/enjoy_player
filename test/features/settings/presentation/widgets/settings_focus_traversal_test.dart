import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_rail_item.dart';

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
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'interactive SettingsRows are individually keyboard-focusable and Tab '
    'traversal moves focus between them',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          Column(
            children: [
              SettingsRow(title: 'Row A', onTap: () {}),
              SettingsRow(title: 'Row B', onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final first = tester.binding.focusManager.primaryFocus;
      expect(first, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final second = tester.binding.focusManager.primaryFocus;
      expect(second, isNotNull);
      expect(
        second,
        isNot(same(first)),
        reason: 'Tab should move focus to the next row, not stay put.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a non-selected rail item shows a visible focus ring only while focused',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          SettingsSectionRailItem(
            icon: Icons.settings,
            label: 'Recording',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final materialFinder = find.descendant(
        of: find.byType(SettingsSectionRailItem),
        matching: find.byType(Material),
      );

      RoundedRectangleBorder shapeOf() =>
          tester.widget<Material>(materialFinder).shape
              as RoundedRectangleBorder;

      expect(shapeOf().side, BorderSide.none);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(shapeOf().side, isNot(BorderSide.none));
      expect(tester.takeException(), isNull);
    },
  );
}
