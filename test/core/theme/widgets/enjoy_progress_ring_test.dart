import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_progress_ring.dart';

const _track = Color(0xFF23232B);
const _fill = Color(0xFF5B4BE8);
const _stroke = 10.0;
const _size = 100.0;

/// Rasterizes [painter] so the arc geometry can be asserted by sampling
/// pixels along the stroke band (center radius = `(size - stroke) / 2`).
///
/// Must run inside `tester.runAsync` — `Picture.toImage` does real async
/// rasterization that never completes in the fake-async test zone.
Future<ui.Image> _render(EnjoyProgressRingPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const ui.Size(_size, _size));
  return recorder.endRecording().toImage(_size.toInt(), _size.toInt());
}

/// Samples the pixel at [angle] (radians, 0 = 3 o'clock, clockwise) on the
/// stroke band's centerline, 50,50 ± 45.
Future<Color> _colorAtAngle(ui.Image image, double angle) async {
  final bytes = await image.toByteData();
  final x = (50 + 45 * math.cos(angle)).round();
  final y = (50 + 45 * math.sin(angle)).round();
  final i = (y * image.width + x) * 4;
  return Color.fromARGB(
    bytes!.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

EnjoyProgressRingPainter _solid(double progress) => EnjoyProgressRingPainter(
  progress: progress,
  trackColor: _track,
  strokeWidth: _stroke,
  progressColor: _fill,
);

void main() {
  test('constructor requires exactly one arc color source', () {
    expect(
      () => EnjoyProgressRingPainter(
        progress: 1,
        trackColor: _track,
        strokeWidth: _stroke,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => EnjoyProgressRingPainter(
        progress: 1,
        trackColor: _track,
        strokeWidth: _stroke,
        progressColor: _fill,
        gradientColors: const [_fill, _fill],
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('shouldRepaint tracks every parameter', () {
    final a = _solid(0.5);
    expect(a.shouldRepaint(_solid(0.5)), isFalse);
    expect(a.shouldRepaint(_solid(0.6)), isTrue);
    expect(
      a.shouldRepaint(
        EnjoyProgressRingPainter(
          progress: 0.5,
          trackColor: Colors.grey,
          strokeWidth: _stroke,
          progressColor: _fill,
        ),
      ),
      isTrue,
    );
    expect(
      a.shouldRepaint(
        EnjoyProgressRingPainter(
          progress: 0.5,
          trackColor: _track,
          strokeWidth: 8,
          progressColor: _fill,
        ),
      ),
      isTrue,
    );
    expect(
      a.shouldRepaint(
        EnjoyProgressRingPainter(
          progress: 0.5,
          trackColor: _track,
          strokeWidth: _stroke,
          progressColor: Colors.red,
        ),
      ),
      isTrue,
    );
  });

  test('shouldRepaint compares gradient colors by value', () {
    final a = EnjoyProgressRingPainter(
      progress: 0.5,
      trackColor: _track,
      strokeWidth: _stroke,
      gradientColors: const [Colors.red, Colors.blue],
    );
    expect(a.shouldRepaint(a), isFalse);
    expect(
      a.shouldRepaint(
        EnjoyProgressRingPainter(
          progress: 0.5,
          trackColor: _track,
          strokeWidth: _stroke,
          gradientColors: const [Colors.red, Colors.blue],
        ),
      ),
      isFalse,
    );
    expect(
      a.shouldRepaint(
        EnjoyProgressRingPainter(
          progress: 0.5,
          trackColor: _track,
          strokeWidth: _stroke,
          gradientColors: const [Colors.red, Colors.green],
        ),
      ),
      isTrue,
    );
  });

  testWidgets('arc covers exactly the swept fraction, clockwise from 12', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await _render(_solid(0.25));
      expect(await _colorAtAngle(image, -math.pi / 4), _fill);
      expect(await _colorAtAngle(image, -math.pi / 2 + 0.2), _fill);
      expect(await _colorAtAngle(image, math.pi / 2), _track);
      expect(await _colorAtAngle(image, 3 * math.pi / 4), _track);
    });
  });

  testWidgets('zero progress paints the track alone', (tester) async {
    await tester.runAsync(() async {
      final image = await _render(_solid(0));
      expect(await _colorAtAngle(image, -math.pi / 2), _track);
      expect(await _colorAtAngle(image, math.pi / 2), _track);
    });
  });

  testWidgets('full progress lights the entire ring (over-target state)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final image = await _render(_solid(1));
      for (final angle in [
        -math.pi / 2,
        0.0,
        math.pi / 2,
        math.pi,
        3 * math.pi / 2 - 0.1,
      ]) {
        expect(await _colorAtAngle(image, angle), _fill);
      }
    });
  });

  testWidgets('gradient arc sweeps the aurora clockwise from 12', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const red = Color(0xFFEE4444);
      const blue = Color(0xFF4444EE);
      final image = await _render(
        EnjoyProgressRingPainter(
          progress: 1,
          trackColor: _track,
          strokeWidth: _stroke,
          gradientColors: [red, blue],
        ),
      );
      final justAfterTop = await _colorAtAngle(image, -math.pi / 2 + 0.15);
      final pastBottom = await _colorAtAngle(image, 3 * math.pi / 4);
      expect(justAfterTop.r, greaterThan(justAfterTop.b));
      expect(pastBottom.b, greaterThan(pastBottom.r));
    });
  });
}
