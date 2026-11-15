import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/dictation/application/dictation_providers.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final provider = dictationSessionCtrlProvider(
    'video',
    'v-1',
    0,
    1000,
    'Hello world',
    'en',
  );

  Widget panel(ProviderContainer container, {VoidCallback? onNextLine}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(provider);
              final ctrl = ref.read(provider.notifier);
              return DictationPanel(
                state: state,
                controller: ctrl,
                onNextLine: onNextLine ?? () {},
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets(
    'DictationPanel renders Voice mode CTA and the checked summary after an answer',
    (tester) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
      var nextLineCalls = 0;

      await tester.pumpWidget(
        panel(container, onNextLine: () => nextLineCalls++),
      );

      expect(find.text('Record retelling'), findsOneWidget);
      expect(find.text('Record retelling (R)'), findsNothing);
      expect(
        find.text('Listen and retell by voice. Tap Record when ready.'),
        findsOneWidget,
      );

      final ctrl = container.read(provider.notifier);
      ctrl.setInputMode(DictationInputMode.text);
      ctrl.updateTextDraft('hello world');
      await tester.pump();
      await ctrl.checkTextAnswer();
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('2 correct'), findsOneWidget);
      expect(find.text('0 missed'), findsOneWidget);
      expect(find.text('0 extra'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Next line'), findsOneWidget);
      await tester.tap(find.text('Next line'));
      await tester.pump();
      expect(nextLineCalls, 1);
    },
  );

  testWidgets('desktop shows the R hotkey variants of the voice copy', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});

      await tester.pumpWidget(panel(container));
      await tester.pump();

      expect(find.text('Record retelling (R)'), findsOneWidget);
      expect(
        find.text(
          'Listen and retell by voice. Tap Record or press R when ready.',
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'TextInput mode handles Enter, Shift+Enter, and IME composing correctly',
    (tester) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
      final ctrl = container.read(provider.notifier);
      ctrl.setInputMode(DictationInputMode.text);
      ctrl.updateTextDraft('hello world');

      await tester.pumpWidget(panel(container));
      await tester.pump();

      expect(container.read(provider).status, DictationAttemptStatus.idle);

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
      expect(container.read(provider).status, DictationAttemptStatus.idle);

      editable.controller.value = const TextEditingValue(
        text: 'hello world',
        composing: TextRange.empty,
      );
      ctrl.updateTextDraft('hello world');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(container.read(provider).status, DictationAttemptStatus.idle);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(container.read(provider).status, DictationAttemptStatus.checked);
    },
  );
}
