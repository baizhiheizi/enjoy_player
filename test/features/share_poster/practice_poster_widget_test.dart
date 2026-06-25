import 'package:enjoy_player/features/share_poster/domain/practice_poster_data.dart';
import 'package:enjoy_player/features/share_poster/presentation/practice_poster_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PracticePosterWidget renders stats and quote lines', (tester) async {
    const data = PracticePosterData(
      title: 'Sample lesson',
      coverSeed: 'seed-abc',
      isVideo: true,
      quote: PracticePosterQuote(
        lines: [
          PracticePosterQuoteLine(
            text: 'so I could get away from the buzzing',
            trailingEllipsis: true,
          ),
          PracticePosterQuoteLine(
            text: 'and focus on the speech patterns',
            trailingEllipsis: true,
          ),
        ],
      ),
      takes: 5,
      sentencesPracticed: 2,
      spokenDurationMs: 125000,
    );

    const labels = PracticePosterLabels(
      tagline: 'Shadow reading',
      takesLabel: 'Takes',
      sentencesLabel: 'Sentences',
      spokenLabel: 'Spoken',
      qrHint: 'Scan to download',
    );

    await tester.binding.setSurfaceSize(const Size(400, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PracticePosterWidget(data: data, labels: labels),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample lesson'), findsOneWidget);
    expect(find.textContaining('so I could get away'), findsOneWidget);
    expect(find.textContaining('and focus on the speech'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('2m 5s'), findsOneWidget);
  });
}
