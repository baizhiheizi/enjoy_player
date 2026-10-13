import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Finder _diskFinder() => find.descendant(
  of: find.byType(DockRecordRing),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is ShapeDecoration &&
        (w.decoration as ShapeDecoration).shape is CircleBorder,
  ),
);

Finder _dotFinder() => find.descendant(
  of: find.byType(DockRecordRing),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.decoration is BoxDecoration,
  ),
);

Container _disk(WidgetTester tester) => tester.widget<Container>(_diskFinder());

BoxDecoration _dotDecoration(WidgetTester tester) =>
    tester.widget<Container>(_dotFinder()).decoration! as BoxDecoration;

void main() {
  group('DockRecordRing', () {
    testWidgets('paints the "you" disk with the theme shadow', (tester) async {
      final t = EnjoyThemeTokens.build(
        ColorScheme.fromSeed(seedColor: Colors.blue),
      );

      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 50,
            dotShape: DockRecordDotShape.circle,
          ),
        ),
      );

      final decoration = _disk(tester).decoration! as ShapeDecoration;
      expect(decoration.color, t.you);
      expect(decoration.shape, isA<CircleBorder>());
      expect(decoration.shadows, t.shadowRecordButton);
      expect(_disk(tester).constraints?.minWidth, 50);
      expect(_disk(tester).constraints?.minHeight, 50);
    });

    testWidgets('circle dot uses BoxShape.circle', (tester) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 50,
            dotShape: DockRecordDotShape.circle,
          ),
        ),
      );

      final dot = _dotDecoration(tester);
      expect(dot.shape, BoxShape.circle);
      expect(dot.borderRadius, isNull);
      expect(
        tester.widget<Container>(_dotFinder()).constraints?.minWidth,
        DockRecordRing.dotSize,
      );
    });

    testWidgets('stopSquare dot uses a rounded-rectangle BoxDecoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 50,
            dotShape: DockRecordDotShape.stopSquare,
          ),
        ),
      );

      final dot = _dotDecoration(tester);
      expect(dot.shape, BoxShape.rectangle);
      expect(
        dot.borderRadius,
        const BorderRadius.all(
          Radius.circular(DockRecordRing.stopDotCornerRadius),
        ),
      );
      expect(
        tester.widget<Container>(_dotFinder()).constraints?.minHeight,
        DockRecordRing.dotSize,
      );
    });

    testWidgets('disk size is independent of the fixed dot size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 38,
            dotShape: DockRecordDotShape.circle,
          ),
        ),
      );

      expect(_disk(tester).constraints?.minWidth, 38);
      expect(
        tester.widget<Container>(_dotFinder()).constraints?.minWidth,
        DockRecordRing.dotSize,
      );
    });
  });
}
