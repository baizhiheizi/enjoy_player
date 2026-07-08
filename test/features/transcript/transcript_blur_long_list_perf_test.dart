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
  testWidgets(
    'blur on: 10k-line transcript scrolls without errors and applies blur to '
    'viewport-visible tiles',
    (tester) async {
      const lineCount = 10000;
      final lines = List.generate(
        lineCount,
        (i) => TranscriptLine(
          text: 'Line $i — quick brown fox jumps over the lazy dog',
          startMs: i * 1000,
          durationMs: 1000,
        ),
      );

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
              body: ListView.builder(
                itemCount: lines.length,
                itemBuilder: (context, i) => TranscriptLineTile(
                  line: lines[i],
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
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down through the list — just assert no exceptions and
      // that tiles are rebuilt (the blur filter is applied per visible tile).
      for (var i = 0; i < 20; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Viewport-visible tiles must have TranscriptBlurText applied.
      expect(find.byType(TranscriptBlurText), findsWidgets);

      // Every visible TranscriptBlurText should be blurred (revealed=false)
      // since no hover or tap-reveal is active.
      final blurs = tester.widgetList<TranscriptBlurText>(
        find.byType(TranscriptBlurText),
      );
      for (final b in blurs) {
        expect(b.revealed, isFalse);
      }
    },
  );
}
