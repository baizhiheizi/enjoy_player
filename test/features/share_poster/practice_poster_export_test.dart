import 'package:enjoy_player/features/share_poster/application/practice_poster_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captureRepaintBoundaryPng returns PNG without debugNeedsPaint', (
    tester,
  ) async {
    final key = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(120, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                width: 36,
                height: 64,
                color: const Color(0xFF112233),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // toImage / toByteData need a real async zone (fakeAsync hangs otherwise).
    final bytes = await tester.runAsync(
      () => captureRepaintBoundaryPng(key, pixelRatio: 1),
    );
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(8));
    // PNG signature
    expect(bytes.sublist(0, 8), [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
  });

  testWidgets('captureRepaintBoundaryPng returns null for missing boundary', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(() => captureRepaintBoundaryPng(key));
    expect(bytes, isNull);
  });
}
