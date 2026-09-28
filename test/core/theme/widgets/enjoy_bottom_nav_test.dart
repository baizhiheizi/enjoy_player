import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_bottom_nav.dart';

Widget _harness({
  required int selectedIndex,
  required List<EnjoyBottomNavDestination> destinations,
  required ValueChanged<int> onSelected,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    home: Scaffold(
      body: EnjoyBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: destinations,
      ),
    ),
  );
}

List<EnjoyBottomNavDestination> _sampleDestinations() {
  return const [
    EnjoyBottomNavDestination(
      icon: EnjoyIcons.home,
      selectedIcon: EnjoyIcons.homeFill,
      label: 'Home',
    ),
    EnjoyBottomNavDestination(
      icon: EnjoyIcons.compass,
      selectedIcon: EnjoyIcons.compassFill,
      label: 'Search',
    ),
    EnjoyBottomNavDestination(
      icon: EnjoyIcons.person,
      selectedIcon: EnjoyIcons.personFill,
      label: 'Profile',
      showBadge: true,
    ),
  ];
}

void main() {
  group('EnjoyBottomNavDestination', () {
    test('defaults showBadge to false and semanticsLabel to null', () {
      const dest = EnjoyBottomNavDestination(
        icon: EnjoyIcons.home,
        selectedIcon: EnjoyIcons.homeFill,
        label: 'Home',
      );
      expect(dest.showBadge, isFalse);
      expect(dest.semanticsLabel, isNull);
      expect(dest.label, 'Home');
    });

    test('honors explicit showBadge + semanticsLabel', () {
      const dest = EnjoyBottomNavDestination(
        icon: EnjoyIcons.home,
        selectedIcon: EnjoyIcons.homeFill,
        label: 'Home',
        semanticsLabel: 'Home tab',
        showBadge: true,
      );
      expect(dest.semanticsLabel, 'Home tab');
      expect(dest.showBadge, isTrue);
    });
  });

  group('EnjoyBottomNav', () {
    testWidgets('renders one item per destination', (tester) async {
      await tester.pumpWidget(
        _harness(
          selectedIndex: 0,
          destinations: _sampleDestinations(),
          onSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EnjoyBottomNav), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('uses selectedIcon for the selected destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          selectedIndex: 1,
          destinations: _sampleDestinations(),
          onSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      // The "Search" destination is selected → its filled icon should appear.
      expect(find.byIcon(EnjoyIcons.compassFill), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.compass), findsNothing);
      // Other destinations should still be unselected.
      expect(find.byIcon(EnjoyIcons.home), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.person), findsOneWidget);
    });

    testWidgets('invokes onDestinationSelected with the tapped index', (
      tester,
    ) async {
      int? tapped;
      await tester.pumpWidget(
        _harness(
          selectedIndex: 0,
          destinations: _sampleDestinations(),
          onSelected: (i) => tapped = i,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });

    testWidgets('draws a badge when showBadge is true', (tester) async {
      await tester.pumpWidget(
        _harness(
          selectedIndex: 0,
          destinations: _sampleDestinations(),
          onSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      // The Profile destination sets showBadge: true — it contributes a small
      // dot container inside its Stack.
      final containers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(EnjoyBottomNav),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final hasDot = containers.any(
        (c) => c.constraints != null && c.constraints!.minWidth == 8,
      );
      expect(hasDot, isTrue);
    });

    testWidgets(
      'selected tab does not overlay a circular marker on the label',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            selectedIndex: 0,
            destinations: _sampleDestinations(),
            onSelected: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        final containers = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(EnjoyBottomNav),
                matching: find.byType(Container),
              ),
            )
            .toList();
        final overlayDots = containers.where(
          (c) =>
              c.constraints != null &&
              c.constraints!.minWidth == 4 &&
              c.constraints!.minHeight == 4,
        );
        expect(overlayDots, isEmpty);
      },
    );

    testWidgets(
      'falls back to semanticsLabel -> label for Semantics container',
      (tester) async {
        const customDest = EnjoyBottomNavDestination(
          icon: EnjoyIcons.settings,
          selectedIcon: EnjoyIcons.settings,
          label: 'Settings',
          semanticsLabel: 'Settings tab',
        );
        await tester.pumpWidget(
          _harness(
            selectedIndex: 0,
            destinations: [customDest],
            onSelected: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        // Resolve the Semantics widget and confirm its label is the override.
        final semantics = tester
            .widgetList<Semantics>(
              find.descendant(
                of: find.byType(EnjoyBottomNav),
                matching: find.byType(Semantics),
              ),
            )
            .toList();
        expect(
          semantics.any((s) => s.properties.label == 'Settings tab'),
          isTrue,
        );
      },
    );

    testWidgets(
      'selectedIndex out of range does not crash and renders all items',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            selectedIndex: 99,
            destinations: _sampleDestinations(),
            onSelected: (_) {},
          ),
        );
        await tester.pumpAndSettle();
        // No destination matches index 99 — none should be styled selected.
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets('renders in light theme without throwing', (tester) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B61FF),
        brightness: Brightness.light,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          home: Scaffold(
            body: EnjoyBottomNav(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: _sampleDestinations(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Regression: the nav's root Align used to expand to the
    // bottomNavigationBar slot's loose maxHeight (the whole screen). Scaffold
    // then reported a full-height bottom widget: contentBottom collapsed to 0,
    // so every floating SnackBar on the shell tripped the "Floating SnackBar
    // presented off screen" layout assert (which aborts frames in debug and
    // froze the player-exit transition), and the body MediaQuery leaked
    // padding.bottom = screen height into AppNotice margins.
    testWidgets(
      'in a bottomNavigationBar slot measures intrinsic height, not the screen',
      (tester) async {
        tester.view.physicalSize = const Size(392.7 * 3, 850.9 * 3);
        tester.view.devicePixelRatio = 3;
        tester.view.padding = const FakeViewPadding(
          left: 0,
          top: 72,
          right: 0,
          bottom: 102,
        );
        tester.view.viewPadding = const FakeViewPadding(
          left: 0,
          top: 72,
          right: 0,
          bottom: 102,
        );
        addTearDown(tester.view.reset);

        final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: scheme,
              useMaterial3: true,
              extensions: [EnjoyThemeTokens.build(scheme)],
            ),
            home: Scaffold(
              extendBody: true,
              body: Builder(
                builder: (context) => Center(
                  child: Text('pad:${MediaQuery.of(context).padding.bottom}'),
                ),
              ),
              bottomNavigationBar: EnjoyBottomNav(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: _sampleDestinations(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final navBox = tester.renderObject<RenderBox>(
          find.byType(EnjoyBottomNav),
        );
        // Capsule + SafeArea insets — far below the 850.9 logical screen.
        expect(navBox.size.height, lessThan(200));
        // extendBody feeds max(padding.bottom, bottomWidgetHeight) into the
        // body MediaQuery; with an intrinsic nav this stays sane too.
        expect(
          double.parse(
            tester
                .widget<Text>(find.textContaining('pad:'))
                .data!
                .split(':')[1],
          ),
          lessThan(200),
        );
      },
    );
  });
}
