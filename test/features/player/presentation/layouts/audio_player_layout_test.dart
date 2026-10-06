import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/presentation/layouts/audio_player_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required Widget transcript}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: AudioPlayerLayout(transcript: transcript)),
    ),
  );
}

void main() {
  testWidgets('renders transcript widget centered with max-width constraint', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(transcript: const Text('transcript body')));
    await tester.pump();

    expect(find.text('transcript body'), findsOneWidget);
    final constrainedBoxes = find
        .byWidgetPredicate((w) => w is ConstrainedBox)
        .evaluate();
    expect(constrainedBoxes, isNotEmpty);
  });

  testWidgets('caps the column at the Listen transcript width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(transcript: const Text('body')));
    await tester.pump();

    final t = EnjoyThemeTokens.build(
      ThemeData(brightness: Brightness.light).colorScheme,
    );
    final constrained = tester.widget<ConstrainedBox>(
      find
          .ancestor(
            of: find.text('body'),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(constrained.constraints.maxWidth, t.transcriptMaxListen);
  });

  testWidgets('widens to the Echo transcript width while a loop is active', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(transcript: const Text('body')));
    final container = ProviderScope.containerOf(
      tester.element(find.text('body')),
    );
    container
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: 0,
          endLineIndex: 0,
          startTimeSeconds: 0,
          endTimeSeconds: 1,
        );
    await tester.pump();

    final t = EnjoyThemeTokens.build(
      ThemeData(brightness: Brightness.light).colorScheme,
    );
    final constrained = tester.widget<ConstrainedBox>(
      find
          .ancestor(
            of: find.text('body'),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(constrained.constraints.maxWidth, t.transcriptMaxEcho);
  });

  testWidgets('keeps a single top safe area and no AppBar', (tester) async {
    await tester.pumpWidget(_wrap(transcript: const Text('body')));
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(SafeArea), findsOneWidget);
  });
}
