import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:enjoy_player/features/transcript/presentation/echo_loop_brackets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _bracketSide = 80.0;
const _bracketColor = Color(0xFF7C3AED);
const _strokeAlpha = 40;

/// Rasterizes the brackets so corner geometry can be asserted by sampling the
/// alpha channel. Must run inside `tester.runAsync` — `Picture.toImage` does
/// real async rasterization that never completes in the fake-async zone.
Future<Uint8List> _renderBrackets() async {
  final recorder = ui.PictureRecorder();
  EchoLoopBrackets(
    color: _bracketColor,
    arm: 20,
    radius: 10,
  ).paint(ui.Canvas(recorder), const ui.Size(_bracketSide, _bracketSide));
  final image = await recorder.endRecording().toImage(
    _bracketSide.toInt(),
    _bracketSide.toInt(),
  );
  final bytes = await image.toByteData();
  return bytes!.buffer.asUint8List();
}

class _Raster {
  _Raster(this.bytes);

  final Uint8List bytes;
  final int side = _bracketSide.toInt();

  bool isStroke(int x, int y) => bytes[((y * side) + x) * 4 + 3] > _strokeAlpha;

  bool isStrokedWithin(int x, int y, int reach) {
    for (var dy = -reach; dy <= reach; dy++) {
      for (var dx = -reach; dx <= reach; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < side && ny < side && isStroke(nx, ny)) {
          return true;
        }
      }
    }
    return false;
  }

  List<int> strokedXs(int y, int xMax) => [
    for (var x = 0; x < xMax; x++)
      if (isStroke(x, y)) x,
  ];
}

void main() {
  testWidgets('every corner mirrors the top-left bracket', (tester) async {
    await tester.runAsync(() async {
      final raster = _Raster(await _renderBrackets());

      for (var y = 0; y < raster.side; y++) {
        for (var x = 0; x < raster.side; x++) {
          if (!raster.isStroke(x, y)) {
            continue;
          }
          final mirrors = <String, bool>{
            'topRight': raster.isStrokedWithin(raster.side - 1 - x, y, 1),
            'bottomLeft': raster.isStrokedWithin(x, raster.side - 1 - y, 1),
            'bottomRight': raster.isStrokedWithin(
              raster.side - 1 - x,
              raster.side - 1 - y,
              1,
            ),
          };
          for (final entry in mirrors.entries) {
            expect(
              entry.value,
              isTrue,
              reason:
                  '(${x.toString()}, ${y.toString()}) is stroked but its '
                  '${entry.key} mirror is not',
            );
          }
        }
      }
    });
  });

  testWidgets('bottom corners hug the corner instead of bulging inward', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final raster = _Raster(await _renderBrackets());

      for (var y = 60; y < raster.side - 10; y++) {
        final xs = raster.strokedXs(y, raster.side ~/ 2);
        expect(
          xs.every((x) => x <= 1),
          isTrue,
          reason:
              'bottom-left row ${y.toString()} should stay a vertical arm near '
              'x=0, but the arc bulged inward to x=${xs.toString()}',
        );
      }

      expect(
        raster.isStroke(4, 78),
        isTrue,
        reason: 'bottom-left arc should turn out to meet the bottom arm',
      );
    });
  });

  testWidgets('pulse dot mounts without an inherited-widget assertion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: EchoRecordingPulseDot(color: Color(0xFF8B2FE0))),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate((w) => w is EchoRecordingPulseDot),
      findsOneWidget,
    );
  });

  testWidgets('pulse dot stays static under reduced animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: EchoRecordingPulseDot(color: Color(0xFF8B2FE0)),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
