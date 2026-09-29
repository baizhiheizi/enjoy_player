import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';

/// Harness matching [app_background_test.dart]: a real theme carrying the
/// [EnjoyThemeTokens] extension, so token expectations line up with what the
/// widget resolves.
class _Harness extends StatelessWidget {
  const _Harness({required this.brightness, required this.child});

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF),
      brightness: brightness,
    );
    return MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF),
      brightness: brightness,
    );
    final tokens = EnjoyThemeTokens.build(scheme);

    group('GlassSurface (${brightness.name})', () {
      testWidgets('renders its child behind a backdrop blur', (tester) async {
        await tester.pumpWidget(
          _Harness(
            brightness: brightness,
            child: const GlassSurface(child: Text('inside')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('inside'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(BackdropFilter),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(ClipRSuperellipse),
          ),
          findsOneWidget,
        );
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(DecoratedBox),
          ),
        );
        final decoration = box.decoration as ShapeDecoration;
        expect(decoration.color, tokens.glassTint);
        expect(
          (decoration.shape as OutlinedBorder).side,
          BorderSide(color: tokens.glassBorder),
        );
      });

      testWidgets('falls back to an opaque popover fill when sigma is zero', (
        tester,
      ) async {
        await tester.pumpWidget(
          _Harness(
            brightness: brightness,
            child: const GlassSurface(sigma: 0, child: Text('inside')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('inside'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(DecoratedBox),
          ),
        );
        final decoration = box.decoration as ShapeDecoration;
        expect(decoration.color, tokens.popover.withValues(alpha: 0.96));
      });
    });
  }

  testWidgets('honors a custom outline for circular chrome', (tester) async {
    await tester.pumpWidget(
      const _Harness(
        brightness: Brightness.dark,
        child: GlassSurface(
          shape: CircleBorder(),
          child: SizedBox(width: 38, height: 38),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final clip = tester.widget<ClipPath>(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(ClipPath),
      ),
    );
    final clipper = clip.clipper as ShapeBorderClipper;
    expect(clipper.shape, isA<CircleBorder>());
    expect(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(ClipRSuperellipse),
      ),
      findsNothing,
    );
  });

  test('rejects combining a custom shape with a corner radius', () {
    expect(
      () => GlassSurface(
        shape: const CircleBorder(),
        borderRadius: 12,
        child: const SizedBox.shrink(),
      ),
      throwsAssertionError,
    );
    expect(
      () => const GlassSurface(shape: CircleBorder(), child: SizedBox.shrink()),
      returnsNormally,
    );
  });

  testWidgets('does not insert a Material into the caller subtree', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        brightness: Brightness.dark,
        child: GlassSurface(child: Text('inside')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
  });
}
