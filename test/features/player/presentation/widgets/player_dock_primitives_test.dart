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

void main() {
  group('DockRecordRing', () {
    ShapeDecoration diskDecoration(WidgetTester tester) =>
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(DockRecordRing),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is Container &&
                              w.decoration is ShapeDecoration &&
                              (w.decoration as ShapeDecoration).shape
                                  is CircleBorder,
                        ),
                      )
                      .first,
                )
                .decoration!
            as ShapeDecoration;

    testWidgets('paints the "you" disk with the theme shadow', (tester) async {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      final t = EnjoyThemeTokens.build(scheme);

      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            inner: 50,
            innerShape: DockRecordDotShape.circle,
          ),
        ),
      );

      final decoration = diskDecoration(tester);
      expect(decoration.color, t.you);
      expect(decoration.shape, isA<CircleBorder>());
      expect(decoration.shadows, t.shadowRecordButton);

      final disk = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DockRecordRing),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is ShapeDecoration &&
                    (w.decoration as ShapeDecoration).shape is CircleBorder,
              ),
            )
            .first,
      );
      expect(disk.constraints?.minWidth, 50);
      expect(disk.constraints?.minHeight, 50);
    });

    testWidgets('circle dot uses BoxShape.circle', (tester) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            inner: 50,
            innerShape: DockRecordDotShape.circle,
          ),
        ),
      );

      final dot = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DockRecordRing),
              matching: find.byWidgetPredicate((w) {
                if (w is! Container || w.decoration is! BoxDecoration) {
                  return false;
                }
                final box = w.decoration as BoxDecoration;
                return box.shape == BoxShape.circle;
              }),
            )
            .first,
      );
      expect(dot.constraints?.minWidth, 16);
      expect(dot.constraints?.minHeight, 16);
    });

    testWidgets('stopSquare dot uses a rounded-rectangle BoxDecoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            inner: 50,
            innerShape: DockRecordDotShape.stopSquare,
          ),
        ),
      );

      final dot = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DockRecordRing),
              matching: find.byWidgetPredicate((w) {
                if (w is! Container || w.decoration is! BoxDecoration) {
                  return false;
                }
                final box = w.decoration as BoxDecoration;
                return box.shape == BoxShape.rectangle &&
                    box.borderRadius is BorderRadius;
              }),
            )
            .first,
      );
      expect(dot.constraints?.minWidth, 16);
      expect(dot.constraints?.minHeight, 16);
    });
  });
}
