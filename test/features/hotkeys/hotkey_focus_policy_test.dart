import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_text_selection_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('primaryFocusBlocksGlobalHotkeys', () {
    testWidgets('blocks when a TextField is focused', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: 'search'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(primaryFocusBlocksGlobalHotkeys(), isTrue);
    });

    testWidgets('does not block transcript selectable text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TranscriptTextSelectionScope(
              child: SelectableText.rich(
                TextSpan(text: 'Hello world'),
                autofocus: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(primaryFocusBlocksGlobalHotkeys(), isFalse);
    });

    testWidgets('blocks SelectableText outside transcript scope', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectableText.rich(
              TextSpan(text: 'Other selectable'),
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(primaryFocusBlocksGlobalHotkeys(), isTrue);
    });
  });

  testWidgets('releasePrimaryFocusForGlobalHotkeys clears editable focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'search'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(primaryFocusBlocksGlobalHotkeys(), isTrue);

    releasePrimaryFocusForGlobalHotkeys();
    await tester.pump();

    expect(primaryFocusBlocksGlobalHotkeys(), isFalse);
  });
}
