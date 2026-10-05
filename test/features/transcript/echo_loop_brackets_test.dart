import 'package:enjoy_player/features/transcript/presentation/echo_loop_brackets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
