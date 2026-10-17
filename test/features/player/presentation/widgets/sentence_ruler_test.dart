import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/transport_slider_position_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'm-ruler';
const _chrome = (
  mediaId: _mediaId,
  dexieTargetType: 'Audio',
  mediaType: 'audio',
  mediaTitle: 'Ruler test',
  thumbnailUrl: null,
  durationSeconds: 600.0,
  language: 'en',
);

Future<ProviderContainer> _pumpRuler(
  WidgetTester tester,
  Stream<Duration> positions,
) async {
  final container = ProviderContainer(
    overrides: [
      transportSliderPositionProvider.overrideWith((ref) => positions),
      transcriptLinesForMediaProvider(_mediaId).overrideWith(
        (ref) => Stream.value(const [
          TranscriptLine(text: 'one', startMs: 0, durationMs: 4000),
          TranscriptLine(text: 'two', startMs: 4000, durationMs: 4000),
        ]),
      ),
      transcriptLineRecordingCountsProvider(
        _mediaId,
      ).overrideWith((ref) => const <int, int>{}),
    ],
  );
  addTearDown(container.dispose);
  final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        home: const Scaffold(
          body: SizedBox(width: 400, child: SentenceRuler(chrome: _chrome)),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('elapsed label follows position ticks without per-tick churn', (
    tester,
  ) async {
    final positions = StreamController<Duration>.broadcast();
    addTearDown(positions.close);
    await _pumpRuler(tester, positions.stream);

    positions.add(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    expect(find.text('0:05'), findsOneWidget);

    for (var i = 0; i < 100; i++) {
      positions.add(Duration(milliseconds: 5000 + i * 4));
    }
    await tester.pump();
    await tester.pump();
    expect(find.text('0:05'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    positions.add(const Duration(seconds: 6));
    await tester.pump();
    await tester.pump();
    expect(find.text('0:06'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ruler paints a static track layer and a playhead layer', (
    tester,
  ) async {
    final positions = StreamController<Duration>.broadcast();
    addTearDown(positions.close);
    await _pumpRuler(tester, positions.stream);

    expect(find.byType(SentenceRuler), findsOneWidget);
    expect(tester.takeException(), isNull);

    positions.add(const Duration(seconds: 300));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
