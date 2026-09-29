import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/nav_item_pill.dart';

import '../../../helpers/pressable_finders.dart';

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
  group('NavItemPill', () {
    testWidgets('renders the label and the unselected icon', (tester) async {
      await tester.pumpWidget(
        _harness(
          NavItemPill(
            icon: EnjoyIcons.home,
            selectedIcon: EnjoyIcons.homeFill,
            label: 'Home',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.home), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.homeFill), findsNothing);
    });

    testWidgets('uses selectedIcon when selected', (tester) async {
      await tester.pumpWidget(
        _harness(
          NavItemPill(
            icon: EnjoyIcons.home,
            selectedIcon: EnjoyIcons.homeFill,
            label: 'Home',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(EnjoyIcons.homeFill), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.home), findsNothing);
    });

    testWidgets('falls back to icon when selectedIcon is null', (tester) async {
      await tester.pumpWidget(
        _harness(
          NavItemPill(
            icon: EnjoyIcons.settings,
            label: 'Settings',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(EnjoyIcons.settings), findsOneWidget);
    });

    testWidgets('iconSize is honored on the rendered Icon', (tester) async {
      await tester.pumpWidget(
        _harness(
          NavItemPill(
            icon: EnjoyIcons.settings,
            label: 'Settings',
            selected: false,
            iconSize: 28,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(EnjoyIcons.settings));
      expect(icon.size, 28);
    });

    testWidgets('forwards maxLines + overflow to the label Text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 80,
            child: NavItemPill(
              icon: EnjoyIcons.settings,
              label: 'A longer label than the available width',
              selected: false,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(
        find.text('A longer label than the available width'),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('invokes onTap and triggers Haptics.selection on press', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          NavItemPill(
            icon: EnjoyIcons.home,
            label: 'Home',
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NavItemPill));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a focus ring only when focused and not selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          NavItemPill(
            icon: EnjoyIcons.home,
            label: 'Home',
            selected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      BorderSide ringSide() =>
          pressableFocusRingSide(tester, find.byType(NavItemPill));

      expect(ringSide(), BorderSide.none);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringSide(), isNot(BorderSide.none));
    });

    testWidgets(
      'does not draw the focus ring when selected, even while focused',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            NavItemPill(
              icon: EnjoyIcons.home,
              selectedIcon: EnjoyIcons.homeFill,
              label: 'Home',
              selected: true,
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        BorderSide ringSide() =>
            pressableFocusRingSide(tester, find.byType(NavItemPill));

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(ringSide(), BorderSide.none);
      },
    );

    testWidgets('renders selected pill in light theme', (tester) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B61FF),
        brightness: Brightness.light,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          home: Scaffold(
            body: NavItemPill(
              icon: EnjoyIcons.home,
              selectedIcon: EnjoyIcons.homeFill,
              label: 'Home',
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
