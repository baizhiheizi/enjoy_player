import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/shadow_reading/presentation/pitch_contour_skeleton.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('the skeleton paints the skeleton painter over the chart band', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const PitchContourChartSkeleton()));
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(PitchContourChartSkeleton),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.painter, isA<PitchContourSkeletonPainter>());
    expect(tester.getSize(find.byType(PitchContourChartSkeleton)).height, 160);
  });

  test('the painter repaints only when the base color changes', () {
    final black = PitchContourSkeletonPainter(baseColor: Colors.black);
    final alsoBlack = PitchContourSkeletonPainter(baseColor: Colors.black);
    final white = PitchContourSkeletonPainter(baseColor: Colors.white);

    expect(black.shouldRepaint(alsoBlack), isFalse);
    expect(black.shouldRepaint(white), isTrue);
  });
}
