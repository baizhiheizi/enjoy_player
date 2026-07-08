import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBlurPrefsCtrl extends TranscriptBlurPreferencesCtrl {
  _FakeBlurPrefsCtrl(this._initial);
  final TranscriptBlurPreferences _initial;

  @override
  Future<TranscriptBlurPreferences> build() async => _initial;

  @override
  Future<void> setEnabled(bool value) async {}

  @override
  Future<void> setTapRevealSeconds(int seconds) async {}
}

void main() {
  Widget harness({
    required TranscriptLine line,
    required TranscriptBlurPreferences prefs,
    String mediaId = 'm1',
    required void Function() onTap,
  }) {
    return ProviderScope(
      overrides: [
        transcriptBlurPreferencesCtrlProvider.overrideWith(
          () => _FakeBlurPrefsCtrl(prefs),
        ),
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
      harness(
        line: line,
        prefs: const TranscriptBlurPreferences(
          enabled: true,
          tapRevealSeconds: 3,
        ),
        onTap: () => tapped++,
      ),
    );
    await tester.pumpAndSettle(); // let async ctrl resolve

    // Initially blurred.
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isFalse,
    );

    // Tap reveals.
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(tapped, 1);
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isTrue,
    );

    // Advance past expiry.
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
          transcriptBlurPreferencesCtrlProvider.overrideWith(
            () => _FakeBlurPrefsCtrl(
              const TranscriptBlurPreferences(
                enabled: true,
                tapRevealSeconds: 3,
              ),
            ),
          ),
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

    // Tap A.
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    // Tap B before A expires.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(InkWell).last);
    await tester.pump();

    final blurs = tester.widgetList<TranscriptBlurText>(
      find.byType(TranscriptBlurText),
    );
    expect(blurs.first.revealed, isFalse, reason: 'A should be re-blurred');
    expect(blurs.last.revealed, isTrue, reason: 'B should be revealed');

    // Clean up: advance past the hold timer so no Timer is pending.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('tap when blur OFF does not start a hold', (tester) async {
    const line = TranscriptLine(text: 'Plain', startMs: 0, durationMs: 2000);
    await tester.pumpWidget(
      harness(
        line: line,
        prefs: TranscriptBlurPreferences.defaults,
        onTap: () {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(
      tester
          .widget<TranscriptBlurText>(find.byType(TranscriptBlurText))
          .revealed,
      isTrue,
    );
  });
}
