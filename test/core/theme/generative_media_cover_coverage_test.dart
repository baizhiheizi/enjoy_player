import 'dart:ui' as ui;

import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingCanvas implements Canvas {
  _RecordingCanvas(this._inner);

  final Canvas _inner;
  int saveLayerCount = 0;
  int drawPathCount = 0;

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    saveLayerCount++;
    _inner.saveLayer(bounds, paint);
  }

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCount++;
    _inner.drawPath(path, paint);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('cover palette', () {
    test('is deterministic per seed', () {
      for (final seed in ['m1', 'craft-42', 'yt-xYz_99', 'a', 'x' * 40]) {
        final a = coverPaletteForSeed(seed);
        final b = coverPaletteForSeed(seed);
        expect(a.background, b.background, reason: 'seed $seed');
        expect(a.gradientStart, b.gradientStart, reason: 'seed $seed');
        expect(a.gradientEnd, b.gradientEnd, reason: 'seed $seed');
      }
    });

    test('every palette stays reachable across a spread of ids', () {
      final seen = <Color>{};
      for (var i = 0; i < 400; i++) {
        seen.add(coverPaletteForSeed('media-$i-with-long-suffix').background);
      }
      expect(seen.length, kGeneratedCoverPalettes.length);
    });

    test('accent resolves to the palette gradient start', () {
      final palette = coverPaletteForSeed('m1');
      expect(generativeAccentForSeed('m1'), palette.gradientStart);
    });
  });

  group('GenerativeMediaCover widget', () {
    testWidgets('paints one cover layer with no per-frame chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 120,
            child: GenerativeMediaCover(seed: 'test-seed', isVideo: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GenerativeMediaCover), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GenerativeMediaCover),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    CustomPaint coverPainter(WidgetTester tester) => tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(GenerativeMediaCover),
        matching: find.byType(CustomPaint),
      ),
    );

    Future<void> pumpSeed(WidgetTester tester, String seed) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 120,
            child: GenerativeMediaCover(seed: seed, isVideo: false),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('same seed repaints nothing across rebuilds', (tester) async {
      await pumpSeed(tester, 'stable-seed');
      final first = coverPainter(tester).painter!;
      await pumpSeed(tester, 'stable-seed');
      final second = coverPainter(tester).painter!;

      expect(first.shouldRepaint(second), isFalse);
      expect(second.shouldRepaint(first), isFalse);
    });

    testWidgets('a different seed triggers a repaint', (tester) async {
      await pumpSeed(tester, 'seed-a');
      final a = coverPainter(tester).painter!;
      await pumpSeed(tester, 'seed-b');
      final b = coverPainter(tester).painter!;

      expect(a.shouldRepaint(b), isTrue);
      expect(b.shouldRepaint(a), isTrue);
    });

    testWidgets('wraps CustomPaint in a RepaintBoundary', (tester) async {
      await pumpSeed(tester, 'boundary-seed');
      expect(
        find.descendant(
          of: find.byType(GenerativeMediaCover),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );
    });

    test('paintLogoMarkPlanes draws all 3 planes without saveLayer', () {
      final recorder = ui.PictureRecorder();
      final canvas = _RecordingCanvas(Canvas(recorder));
      const rect = Rect.fromLTWH(0, 0, 120, 120);
      final shader = const LinearGradient(
        colors: [Colors.blue, Colors.purple],
      ).createShader(rect);

      paintLogoMarkPlanes(canvas, destination: rect, shader: shader);
      recorder.endRecording().dispose();

      expect(canvas.saveLayerCount, 0);
      expect(canvas.drawPathCount, 3);
    });
  });
}
