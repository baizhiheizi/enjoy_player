import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/shadow_reading/presentation/pitch_contour_legend.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('the legend toggle renders its label and fires onTap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        PitchContourLegendToggle(
          label: 'Waveform',
          swatch: const PitchContourLegendSwatch.envelope(Colors.red),
          selected: true,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waveform'), findsOneWidget);

    await tester.tap(find.text('Waveform'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('the legend toggle exposes its toggled state to semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PitchContourLegendToggle(
          label: 'Your pitch',
          swatch: const PitchContourLegendSwatch.line(Colors.blue),
          selected: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = tester.getSemantics(find.byType(PitchContourLegendToggle));
    expect(selected.flagsCollection.isToggled, Tristate.isTrue);
    expect(selected.flagsCollection.isButton, isTrue);

    await tester.pumpWidget(
      wrap(
        PitchContourLegendToggle(
          label: 'Your pitch',
          swatch: const PitchContourLegendSwatch.line(Colors.blue),
          selected: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final unselected = tester.getSemantics(
      find.byType(PitchContourLegendToggle),
    );
    expect(unselected.flagsCollection.isToggled, Tristate.isFalse);
  });

  testWidgets('the unselected legend toggle dims its content', (tester) async {
    await tester.pumpWidget(
      wrap(
        PitchContourLegendToggle(
          label: 'Original pitch',
          swatch: const PitchContourLegendSwatch.band(Colors.green),
          selected: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(PitchContourLegendToggle),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.45);
  });

  testWidgets('each swatch kind renders its own geometry', (tester) async {
    await tester.pumpWidget(
      wrap(const PitchContourLegendSwatch.band(Colors.green)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(PitchContourLegendSwatch)),
      const Size(16, 7),
    );

    await tester.pumpWidget(
      wrap(const PitchContourLegendSwatch.line(Colors.blue)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(PitchContourLegendSwatch)),
      const Size(16, 3),
    );

    await tester.pumpWidget(
      wrap(const PitchContourLegendSwatch.envelope(Colors.red)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(PitchContourLegendSwatch)),
      const Size(16, 9),
    );
  });
}
