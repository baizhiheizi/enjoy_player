import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/presentation/widgets/video_paused_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGate(
    WidgetTester tester, {
    required bool playing,
    bool buffering = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerIsPlayingProvider.overrideWith((ref) => Stream.value(playing)),
          playerIsBufferingProvider.overrideWith(
            (ref) => Stream.value(buffering),
          ),
        ],
        child: const MaterialApp(
          home: VideoPausedGate(child: Icon(Icons.play_arrow)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('gate shows and hit-tests its child while paused', (
    tester,
  ) async {
    await pumpGate(tester, playing: false);

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 1.0);
    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isFalse);
  });

  testWidgets('gate hides and blocks its child while playing', (tester) async {
    await pumpGate(tester, playing: true);

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0.0);
    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('gate shows while buffering even though playing', (tester) async {
    await pumpGate(tester, playing: true, buffering: true);

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 1.0);
    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isFalse);
  });
}
