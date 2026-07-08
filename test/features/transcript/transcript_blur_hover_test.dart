import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
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
  Widget harness(Widget child) {
    return ProviderScope(
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
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'mouse hover over a blurred cue reveals it; mouse out re-blurs',
    (tester) async {
      const line = TranscriptLine(
        text: 'Hover me',
        startMs: 0,
        durationMs: 2000,
      );
      await tester.pumpWidget(
        harness(
          TranscriptLineTile(
            line: line,
            mediaId: 'm1',
            secondaryText: null,
            isActive: false,
            inEcho: false,
            groupedInEcho: false,
            selectable: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially blurred.
      final initial = tester.widget<TranscriptBlurText>(
        find.byType(TranscriptBlurText),
      );
      expect(initial.revealed, isFalse);

      // Create a mouse gesture and move into the tile.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      final tileCenter = tester.getCenter(find.byType(TranscriptLineTile));
      await gesture.moveTo(tileCenter);
      await tester.pumpAndSettle();

      final revealed = tester.widget<TranscriptBlurText>(
        find.byType(TranscriptBlurText),
      );
      expect(revealed.revealed, isTrue);

      // Move pointer away from the tile.
      await gesture.moveTo(const Offset(-100, -100));
      await tester.pumpAndSettle();

      final reblurred = tester.widget<TranscriptBlurText>(
        find.byType(TranscriptBlurText),
      );
      expect(reblurred.revealed, isFalse);

      await gesture.removePointer();
    },
  );

  testWidgets(
    'when blur practice is OFF the cue is always revealed regardless of hover',
    (tester) async {
      const line = TranscriptLine(
        text: 'Always visible',
        startMs: 0,
        durationMs: 2000,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transcriptBlurPreferencesCtrlProvider.overrideWith(
              () => _FakeBlurPrefsCtrl(TranscriptBlurPreferences.defaults),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TranscriptLineTile(
                line: line,
                mediaId: 'm1',
                secondaryText: null,
                isActive: false,
                inEcho: false,
                groupedInEcho: false,
                selectable: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final w = tester.widget<TranscriptBlurText>(
        find.byType(TranscriptBlurText),
      );
      expect(w.revealed, isTrue);
    },
  );
}
