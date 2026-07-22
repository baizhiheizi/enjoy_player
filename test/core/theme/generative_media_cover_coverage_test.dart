import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seeds chosen to exercise different pattern branches in _computeSpec.
/// Pattern type = hashToNumber(seed, 4) % 5, so we pick seeds that cover
/// circles (0), rectangles (1), waves (2), grid (3), diagonal (4).
const _seeds = [
  'circles-pattern-seed-001',
  'rectangles-pattern-seed-002',
  'waves-pattern-seed-003',
  'grid-pattern-seed-004',
  'diagonal-pattern-seed-005',
  'another-seed-abc',
  'xyz-987-foo',
  'short',
  'a',
  'a-longer-seed-with-many-characters-to-exercise-hash',
];

void main() {
  group('GenerativeMediaCover widget', () {
    testWidgets('renders Stack with two CustomPaint layers and icon (video)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'test-seed', isVideo: true),
          ),
        ),
      );

      expect(find.byType(GenerativeMediaCover), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GenerativeMediaCover),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(2),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.audiotrack_rounded), findsNothing);
    });

    testWidgets('renders audio icon when isVideo is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'test-seed', isVideo: false),
          ),
        ),
      );

      expect(find.byIcon(Icons.audiotrack_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('renders DecoratedBox with circle shape for glass icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'glass-test', isVideo: true),
          ),
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('icon has correct size and padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'icon-size', isVideo: false),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.audiotrack_rounded));
      expect(icon.size, 28);

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byIcon(Icons.audiotrack_rounded),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.all(14));
    });
  });

  group('GenerativeMediaCover paints without errors for various seeds', () {
    for (final seed in _seeds) {
      testWidgets('seed: "$seed"', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 300,
              height: 300,
              child: GenerativeMediaCover(seed: seed, isVideo: true),
            ),
          ),
        );

        // Verify the widget tree rendered without exceptions.
        expect(find.byType(GenerativeMediaCover), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('GenerativeMediaCover repaint with different seed', () {
    testWidgets('changing seed triggers repaint without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'seed-A', isVideo: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Change seed to force shouldRepaint == true on both painters.
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'seed-B', isVideo: false),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.audiotrack_rounded), findsOneWidget);
    });

    testWidgets('same seed does not trigger unnecessary repaint errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'stable', isVideo: true),
          ),
        ),
      );

      // Rebuild with same seed — shouldRepaint should return false for
      // identical specs but the widget still renders correctly.
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: GenerativeMediaCover(seed: 'stable', isVideo: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });

  group('GenerativeMediaCover at various sizes', () {
    testWidgets('renders correctly at zero-ish size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 1,
            height: 1,
            child: GenerativeMediaCover(seed: 'tiny', isVideo: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly at large size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 1920,
            height: 1080,
            child: GenerativeMediaCover(seed: 'large-canvas', isVideo: false),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly with non-square aspect ratio', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 400,
            height: 100,
            child: GenerativeMediaCover(seed: 'wide', isVideo: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('generativeAccentForSeed determinism across pattern types', () {
    test('different seeds can produce different accents', () {
      final accents = _seeds
          .map((s) => generativeAccentForSeed(s).toARGB32())
          .toSet();
      // With 10 diverse seeds we expect more than 1 unique accent.
      expect(accents.length, greaterThan(1));
    });

    test('same seed always produces the same accent', () {
      for (final seed in _seeds) {
        expect(
          generativeAccentForSeed(seed).toARGB32(),
          generativeAccentForSeed(seed).toARGB32(),
        );
      }
    });
  });

  group('hashToNumber edge cases', () {
    test('single character string', () {
      expect(hashToNumber('x', 0), greaterThan(0));
    });

    test('offset larger than string length wraps via modulo', () {
      // Should not throw even with large offsets.
      expect(hashToNumber('ab', 100), isA<int>());
    });

    test('offset=0 vs offset=4 differ for long strings', () {
      const s = 'abcdefghijklmnop';
      expect(hashToNumber(s, 0), isNot(hashToNumber(s, 4)));
    });
  });
}
