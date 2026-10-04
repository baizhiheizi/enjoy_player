import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';

Widget _host({required Brightness brightness, required Widget child}) {
  return MaterialApp(
    theme: buildAppTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

EnjoyThemeTokens _tokens(Brightness brightness) => EnjoyThemeTokens.build(
  ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
);

void main() {
  testWidgets('brand button paints the gradient with an opaque white label', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          child: EnjoyButton.brand(onPressed: () {}, child: const Text('Go')),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final fg = button.style?.foregroundColor?.resolve({});
      expect(fg, Colors.white);
      expect(button.style?.backgroundBuilder, isNotNull);
    }
  });

  testWidgets('primary button uses the ink fill and its on-primary label', (
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
      final t = _tokens(brightness);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), t.primary);
      expect(button.style?.foregroundColor?.resolve({}), t.onPrimary);
      expect(button.style?.backgroundBuilder, isNull);
    }
  });

  testWidgets('secondary button is paper with a line hairline', (tester) async {
    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        child: EnjoyButton.secondary(onPressed: () {}, child: const Text('Go')),
      ),
    );
    await tester.pumpAndSettle();
    final t = _tokens(Brightness.dark);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), t.paper);
    expect(button.style?.side?.resolve({})?.color, t.line);
  });

  testWidgets('tonal stays an alias of secondary until the rename pass', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        brightness: Brightness.light,
        child: EnjoyButton.tonal(onPressed: () {}, child: const Text('Go')),
      ),
    );
    await tester.pumpAndSettle();
    final t = _tokens(Brightness.light);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), t.paper);
    expect(button.style?.side?.resolve({})?.color, t.line);
  });

  testWidgets('destructive button is a solid danger fill with a white label', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        _host(
          brightness: brightness,
          child: EnjoyButton.destructive(
            onPressed: () {},
            child: const Text('Delete'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = _tokens(brightness);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), t.danger);
      expect(button.style?.foregroundColor?.resolve({}), Colors.white);
    }
  });

  testWidgets('sizes follow the Duet control heights at radius 12', (
    tester,
  ) async {
    final t = _tokens(Brightness.light);
    final expected = {
      EnjoyButtonSize.small: t.controlHeightSm,
      EnjoyButtonSize.medium: t.controlHeight,
      EnjoyButtonSize.large: t.controlHeightLg,
    };
    for (final entry in expected.entries) {
      await tester.pumpWidget(
        _host(
          brightness: Brightness.light,
          child: EnjoyButton.brand(
            onPressed: () {},
            size: entry.key,
            child: const Text('Go'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.minimumSize?.resolve({})!.height, entry.value);
      final border =
          button.style!.shape!.resolve({}) as RoundedSuperellipseBorder;
      expect(
        border.borderRadius.resolve(TextDirection.ltr).topLeft.x,
        t.radiusControl,
      );
    }
  });
}
