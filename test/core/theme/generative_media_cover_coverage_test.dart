import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
