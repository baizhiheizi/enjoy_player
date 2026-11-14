import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/transcript_settings_overrides.dart';

void main() {
  Widget harness({
    required TranscriptLine line,
    required bool blurActive,
    String mediaId = 'm1',
    required void Function() onTap,
  }) {
    return ProviderScope(
      overrides: [
        transcriptBlurModeProvider.overrideWith(() => _BlurMode(blurActive)),
        ...transcriptWordPracticeOffOverrides(),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TranscriptLineTile(
            line: line,
            mediaId: mediaId,
            secondaryText: null,
            isActive: false,
            inEcho: false,
            groupedInEcho: false,
            selectable: false,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  testWidgets('tap reveals and starts hold; expiry re-blurs', (tester) async {
    const line = TranscriptLine(text: 'Tap me', startMs: 0, durationMs: 2000);
    var tapped = 0;
    await tester.pumpWidget(
      harness(line: line, blurActive: true, onTap: () => tapped++),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isFalse,
    );

    await tester.tap(find.byType(EnjoyPressable));
    await tester.pump();
    expect(tapped, 1);
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isTrue,
    );

    await tester.pump(const Duration(seconds: 4));
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isFalse,
    );
  });

  testWidgets('second tap replaces the hold and re-blurs the first cue', (
    tester,
  ) async {
    const lineA = TranscriptLine(text: 'A', startMs: 0, durationMs: 1000);
    const lineB = TranscriptLine(text: 'B', startMs: 1000, durationMs: 1000);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptBlurModeProvider.overrideWith(() => _BlurMode(true)),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                TranscriptLineTile(
                  line: lineA,
                  mediaId: 'm1',
                  secondaryText: null,
                  isActive: false,
                  inEcho: false,
                  groupedInEcho: false,
                  selectable: false,
                  onTap: () {},
                ),
                TranscriptLineTile(
                  line: lineB,
                  mediaId: 'm1',
                  secondaryText: null,
                  isActive: false,
                  inEcho: false,
                  groupedInEcho: false,
                  selectable: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EnjoyPressable).first);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(EnjoyPressable).last);
    await tester.pump();

    final blurs = tester.widgetList<TranscriptBlurText>(
      find.byType(TranscriptBlurText),
    );
    expect(blurs.first.revealed, isFalse, reason: 'A should be re-blurred');
    expect(blurs.last.revealed, isTrue, reason: 'B should be revealed');

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('tap when blur OFF does not start a hold', (tester) async {
    const line = TranscriptLine(text: 'Plain', startMs: 0, durationMs: 2000);
    await tester.pumpWidget(
      harness(line: line, blurActive: false, onTap: () {}),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EnjoyPressable));
    await tester.pump();
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isTrue,
    );
  });

  testWidgets('long-press reveals without seeking; expiry re-blurs', (
    tester,
  ) async {
    const line = TranscriptLine(text: 'Hold me', startMs: 0, durationMs: 2000);
    var tapped = 0;
    await tester.pumpWidget(
      harness(line: line, blurActive: true, onTap: () => tapped++),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(EnjoyPressable));
    await tester.pump();
    expect(tapped, 0);
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isTrue,
    );

    await tester.pump(const Duration(seconds: 4));
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isFalse,
    );
  });

  testWidgets('long-press on hidden shapes of a selectable cue reveals', (
    tester,
  ) async {
    const line = TranscriptLine(
      text: 'Loop line',
      startMs: 0,
      durationMs: 2000,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptBlurModeProvider.overrideWith(() => _BlurMode(true)),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TranscriptLineTile(
              line: line,
              mediaId: 'm1',
              secondaryText: null,
              isActive: true,
              inEcho: false,
              groupedInEcho: false,
              selectable: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isFalse,
    );

    await tester.longPress(find.byType(TranscriptBlurText));
    await tester.pump();
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isTrue,
    );
  });

  testWidgets('desktop press-release keeps tap seek when blur off', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      const line = TranscriptLine(
        text: 'Slow click',
        startMs: 0,
        durationMs: 2000,
      );
      var tapped = 0;
      await tester.pumpWidget(
        harness(line: line, blurActive: false, onTap: () => tapped++),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(EnjoyPressable));
      await tester.pump();
      expect(tapped, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop press-release keeps tap seek + reveal when blur on', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      const line = TranscriptLine(
        text: 'Slow click',
        startMs: 0,
        durationMs: 2000,
      );
      var tapped = 0;
      await tester.pumpWidget(
        harness(line: line, blurActive: true, onTap: () => tapped++),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(EnjoyPressable));
      await tester.pump();
      expect(tapped, 1);
      expect(
        tester
            .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
            .revealed,
        isTrue,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hidden secondary line shapes reveal on tap and long-press', (
    tester,
  ) async {
    const line = TranscriptLine(
      text: 'Loop line',
      startMs: 0,
      durationMs: 2000,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptBlurModeProvider.overrideWith(() => _BlurMode(true)),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TranscriptLineTile(
              line: line,
              mediaId: 'm1',
              secondaryText: '译文行',
              isActive: true,
              inEcho: false,
              groupedInEcho: false,
              selectable: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final blurs = find.byType(TranscriptBlurText);
    expect(blurs, findsNWidgets(2));
    bool revealed() => tester.widget<TranscriptBlurText>(blurs.first).revealed;
    expect(revealed(), isFalse);

    await tester.tap(blurs.last);
    await tester.pump();
    expect(revealed(), isTrue);

    await tester.pump(const Duration(seconds: 4));
    expect(revealed(), isFalse);

    await tester.longPress(blurs.last);
    await tester.pump();
    expect(revealed(), isTrue);
  });
}

class _BlurMode extends TranscriptBlurMode {
  _BlurMode(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}
