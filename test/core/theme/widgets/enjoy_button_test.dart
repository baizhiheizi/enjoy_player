import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';

Widget _host({required Brightness brightness, required Widget child}) {
  return MaterialApp(
    theme: buildAppTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('lit fill decorations (aurora signature kit)', () {
    const base = Color(0xFF5B4BE8);

    test('enjoyLitFillDecoration paints the canonical sheen and shape', () {
      const shape = CircleBorder();
      final decoration = enjoyLitFillDecoration(base: base, shape: shape);

      final gradient = decoration.gradient;
      expect(gradient, isA<LinearGradient>());
      final linear = gradient as LinearGradient;
      expect(linear.begin, Alignment.topCenter);
      expect(linear.end, Alignment.bottomCenter);
      expect(linear.colors[0], Color.lerp(base, Colors.white, 0.10));
      expect(linear.colors[1], base);
      expect(decoration.shape, shape);
      expect(decoration.shadows, isEmpty);
    });

    test('enjoyLitFillDecoration carries the fill override and one shadow', () {
      final shadow = enjoyLitShadow(base, alpha: 0.38, blurRadius: 16);
      final fill = Color.lerp(base, Colors.white, 0.08)!;
      final decoration = enjoyLitFillDecoration(
        base: base,
        shape: const StadiumBorder(),
        fill: fill,
        sheen: 0.14,
        shadow: shadow,
      );

      final linear = decoration.gradient as LinearGradient;
      expect(linear.colors[0], Color.lerp(fill, Colors.white, 0.14));
      expect(linear.colors[1], fill);
      expect(decoration.shadows, [shadow]);
    });

    test('enjoyLitShadow defaults to the button glow', () {
      final shadow = enjoyLitShadow(base);
      expect(shadow.color, base.withValues(alpha: 0.32));
      expect(shadow.blurRadius, 14);
      expect(shadow.spreadRadius, -5);
      expect(shadow.offset, const Offset(0, 5));
    });

    test(
      'enjoyLitHighlightSide is a 1px white ring at the canonical alpha',
      () {
        final side = enjoyLitHighlightSide();
        expect(side.width, 1);
        expect(side.color, Colors.white.withValues(alpha: 0.14));
        expect(
          enjoyLitHighlightSide(alpha: 0.16).color,
          Colors.white.withValues(alpha: 0.16),
        );
      },
    );
  });

  testWidgets('primary button keeps an opaque label in light and dark', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          child: EnjoyButton.primary(onPressed: () {}, child: const Text('Go')),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('Go'));
      expect(text.style?.color, isNull);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final fg = button.style?.foregroundColor?.resolve({});
      expect(fg, isNotNull);
      expect(fg!.a, 1.0);
    }
  });

  testWidgets('hover brightens the lit fill without fading the label', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          child: EnjoyButton.primary(onPressed: () {}, child: const Text('Go')),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      const hovered = {WidgetState.hovered};
      final idleFg = button.style?.foregroundColor?.resolve({});
      final hoverFg = button.style?.foregroundColor?.resolve(hovered);
      expect(idleFg?.a, 1.0);
      expect(hoverFg, idleFg);
      expect(button.style?.backgroundBuilder, isNotNull);
    }
  });

  testWidgets('secondary hover shows a wash without fading the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: EnjoyButton.secondary(onPressed: () {}, child: const Text('Go')),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    const hovered = {WidgetState.hovered};
    expect(
      button.style?.foregroundColor?.resolve(hovered),
      button.style?.foregroundColor?.resolve({}),
    );
    final hoverOverlay = button.style?.overlayColor?.resolve(hovered);
    expect(hoverOverlay, isNotNull);
    expect(hoverOverlay!.a, greaterThan(0));
  });
}
