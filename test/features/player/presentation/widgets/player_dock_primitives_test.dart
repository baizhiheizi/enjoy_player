import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_lens_provider.dart';
import 'package:enjoy_player/features/player/domain/player_lens.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Finder _diskFinder() => find.descendant(
  of: find.byType(DockRecordRing),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is ShapeDecoration &&
        (w.decoration as ShapeDecoration).shape is CircleBorder,
  ),
);

Finder _dotFinder() => find.descendant(
  of: find.byType(DockRecordRing),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.decoration is BoxDecoration,
  ),
);

Container _disk(WidgetTester tester) => tester.widget<Container>(_diskFinder());

BoxDecoration _dotDecoration(WidgetTester tester) =>
    tester.widget<Container>(_dotFinder()).decoration! as BoxDecoration;

Widget _recordingHost(EchoState echo) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  return ProviderScope(
    overrides: [echoModeProvider.overrideWithValue(echo)],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Center(child: DockRecordingProgress())),
    ),
  );
}

final _readoutCueProvider = NotifierProvider<_ReadoutCueNotifier, int>(
  _ReadoutCueNotifier.new,
);

class _ReadoutCueNotifier extends Notifier<int> {
  @override
  int build() => 2;
}

final _readoutWordProvider = NotifierProvider<_ReadoutWordNotifier, int?>(
  _ReadoutWordNotifier.new,
);

class _ReadoutWordNotifier extends Notifier<int?> {
  @override
  int? build() => null;
}

void main() {
  group('DockReadout', () {
    const mediaId = 'readout-media';

    Future<ProviderContainer> pumpReadout(WidgetTester tester) async {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      final container = ProviderContainer(
        overrides: [
          playerLensProvider.overrideWithValue(PlayerLens.listen),
          transcriptLinesForMediaProvider(mediaId).overrideWith(
            (ref) => Stream.value(
              List.generate(
                5,
                (i) => TranscriptLine(
                  text: 'Line $i',
                  startMs: i * 1000,
                  durationMs: 1000,
                ),
              ),
            ),
          ),
          transcriptPlaybackHighlightProvider(mediaId).overrideWith(
            (ref) => (
              cueIndex: ref.watch(_readoutCueProvider),
              wordIndex: ref.watch(_readoutWordProvider),
            ),
          ),
          transcriptLineRecordingCountsProvider(
            mediaId,
          ).overrideWith((ref) => const <int, int>{0: 2}),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: scheme,
              useMaterial3: true,
              extensions: [EnjoyThemeTokens.build(scheme)],
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Center(
                child: DockReadout(mediaId: mediaId, recording: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('shows the listen-mode line position and practised count', (
      tester,
    ) async {
      await pumpReadout(tester);

      expect(find.text('Line 3 of 5'), findsOneWidget);
      expect(find.text('1 line practised'), findsOneWidget);
    });

    testWidgets('updates the line position when the cue changes', (
      tester,
    ) async {
      final container = await pumpReadout(tester);

      container.read(_readoutCueProvider.notifier).state = 3;
      await tester.pump();

      expect(find.text('Line 4 of 5'), findsOneWidget);
    });

    testWidgets('does not rebuild on karaoke word ticks', (tester) async {
      final container = await pumpReadout(tester);
      final before = tester.widget<Text>(find.text('Line 3 of 5'));

      container.read(_readoutWordProvider.notifier).state = 4;
      await tester.pump();

      expect(tester.widget<Text>(find.text('Line 3 of 5')), same(before));
    });
  });

  group('DockRecordRing', () {
    testWidgets('paints the "you" disk with the theme shadow', (tester) async {
      final t = EnjoyThemeTokens.build(
        ColorScheme.fromSeed(seedColor: Colors.blue),
      );

      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 50,
            dotShape: DockRecordDotShape.circle,
          ),
        ),
      );

      final decoration = _disk(tester).decoration! as ShapeDecoration;
      expect(decoration.color, t.you);
      expect(decoration.shape, isA<CircleBorder>());
      expect(decoration.shadows, t.shadowRecordButton);
      expect(_disk(tester).constraints?.minWidth, 50);
      expect(_disk(tester).constraints?.minHeight, 50);
    });

    testWidgets('circle dot uses BoxShape.circle', (tester) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 50,
            dotShape: DockRecordDotShape.circle,
          ),
        ),
      );

      final dot = _dotDecoration(tester);
      expect(dot.shape, BoxShape.circle);
      expect(dot.borderRadius, isNull);
      expect(
        tester.widget<Container>(_dotFinder()).constraints?.minWidth,
        DockRecordRing.dotSize,
      );
    });

    testWidgets('stopSquare dot uses a rounded-rectangle BoxDecoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 50,
            dotShape: DockRecordDotShape.stopSquare,
          ),
        ),
      );

      final dot = _dotDecoration(tester);
      expect(dot.shape, BoxShape.rectangle);
      expect(
        dot.borderRadius,
        const BorderRadius.all(
          Radius.circular(DockRecordRing.stopDotCornerRadius),
        ),
      );
      expect(
        tester.widget<Container>(_dotFinder()).constraints?.minHeight,
        DockRecordRing.dotSize,
      );
    });

    testWidgets('disk size is independent of the fixed dot size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DockRecordRing(
            diskSize: 38,
            dotShape: DockRecordDotShape.circle,
          ),
        ),
      );

      expect(_disk(tester).constraints?.minWidth, 38);
      expect(
        tester.widget<Container>(_dotFinder()).constraints?.minWidth,
        DockRecordRing.dotSize,
      );
    });
  });

  group('DockRecordingProgress', () {
    testWidgets('counts elapsed tenths against the echo loop target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _recordingHost(
          const EchoState(
            active: true,
            startLineIndex: 0,
            endLineIndex: 0,
            startTimeSeconds: 0,
            endTimeSeconds: 4.2,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2500));

      expect(find.text('Recording · 2.5s of 4.2s'), findsOneWidget);
    });

    testWidgets('clamps the elapsed readout at the loop target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _recordingHost(
          const EchoState(
            active: true,
            startLineIndex: 0,
            endLineIndex: 0,
            startTimeSeconds: 0,
            endTimeSeconds: 4.2,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('Recording · 4.2s of 4.2s'), findsOneWidget);
    });

    testWidgets('falls back to a bare elapsed readout without a loop target', (
      tester,
    ) async {
      await tester.pumpWidget(_recordingHost(EchoState.inactive));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('1.5'), findsOneWidget);
    });
  });
}
