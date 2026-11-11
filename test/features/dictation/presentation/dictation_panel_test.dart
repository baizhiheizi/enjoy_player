import 'package:enjoy_player/features/dictation/application/dictation_controller.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scope = DictationScope(
    targetType: 'video',
    targetId: 'v-1',
    referenceStartMs: 0,
    referenceDurationMs: 1000,
    referenceText: 'Hello world',
    language: 'en',
  );

  testWidgets(
    'DictationPanel renders Voice mode CTA and NextLine action when checked',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var state = const DictationSessionState(
        mode: DictationInputMode.voice,
        status: DictationAttemptStatus.idle,
      );

      final ctrl = DictationController(
        ref: container.read(Provider((ref) => ref)),
        scope: scope,
        getState: () => state,
        setState: (next) => state = next,
      );

      var nextLineCalled = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DictationPanel(
                    state: state,
                    controller: ctrl,
                    onNextLine: () {
                      nextLineCalled = true;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Record retelling (R)'), findsOneWidget);

      state = state.copyWith(
        status: DictationAttemptStatus.checked,
        activeDiff: () => const DictationDiffResult(
          tokens: [],
          accuracy: 90,
          correctWords: 2,
          missedWords: 0,
          extraWords: 0,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DictationPanel(
                    state: state,
                    controller: ctrl,
                    onNextLine: () {
                      nextLineCalled = true;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('90%'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Next line'), findsOneWidget);

      await tester.tap(find.text('Next line'));
      expect(nextLineCalled, isTrue);
    },
  );

  testWidgets(
    'TextInput mode handles Enter, Shift+Enter, and IME composing correctly',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var state = const DictationSessionState(
        mode: DictationInputMode.text,
        status: DictationAttemptStatus.idle,
        textDraft: 'hello world',
      );

      final ctrl = DictationController(
        ref: container.read(Provider((ref) => ref)),
        scope: scope,
        getState: () => state,
        setState: (next) => state = next,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DictationPanel(
                    state: state,
                    controller: ctrl,
                    onNextLine: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      editable.controller.value = const TextEditingValue(
        text: 'hel',
        composing: TextRange(start: 0, end: 3),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(state.status, DictationAttemptStatus.idle);

      editable.controller.value = const TextEditingValue(
        text: 'hello world',
        composing: TextRange.empty,
      );
      state = state.copyWith(textDraft: 'hello world');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(state.status, DictationAttemptStatus.idle);
    },
  );
}
