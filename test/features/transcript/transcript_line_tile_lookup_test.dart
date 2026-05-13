import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';

void main() {
  testWidgets('selectable transcript line uses SelectableText', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptLineTile(
            line: const TranscriptLine(
              text: 'Hello world',
              startMs: 0,
              durationMs: 2000,
            ),
            secondaryText: null,
            isActive: true,
            inEcho: false,
            groupedInEcho: false,
            selectable: true,
            onLookupRequested: (_) {},
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('non-selectable transcript line uses plain Text.rich', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptLineTile(
            line: const TranscriptLine(
              text: 'Hello world',
              startMs: 0,
              durationMs: 2000,
            ),
            secondaryText: null,
            isActive: false,
            inEcho: false,
            groupedInEcho: false,
            selectable: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsNothing);
    expect(find.byType(InkWell), findsOneWidget);
  });
}
