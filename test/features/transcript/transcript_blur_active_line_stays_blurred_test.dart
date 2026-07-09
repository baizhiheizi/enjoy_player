import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _BlurMode extends TranscriptBlurMode {
  _BlurMode(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

void main() {
  testWidgets(
    'active playback cue is never auto-revealed in blur practice mode',
    (tester) async {
      const lines = [
        TranscriptLine(text: 'A', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'B', startMs: 1000, durationMs: 1000),
        TranscriptLine(text: 'C', startMs: 2000, durationMs: 1000),
      ];

      Widget buildTree(int activeIndex) {
        return ProviderScope(
          overrides: [
            transcriptBlurModeProvider.overrideWith(() => _BlurMode(true)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  for (var i = 0; i < lines.length; i++)
                    TranscriptLineTile(
                      key: ValueKey('cue-$i'),
                      line: lines[i],
                      mediaId: 'm1',
                      secondaryText: null,
                      isActive: i == activeIndex,
                      inEcho: false,
                      groupedInEcho: false,
                      selectable: false,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        );
      }

      for (final activeIndex in [0, 1, 2]) {
        await tester.pumpWidget(buildTree(activeIndex));
        await tester.pumpAndSettle();
        for (var i = 0; i < lines.length; i++) {
          final blur = tester.widget<TranscriptBlurText>(
            find
                .descendant(
                  of: find.byKey(ValueKey('cue-$i')),
                  matching: find.byType(TranscriptBlurText),
                )
                .first,
          );
          expect(
            blur.revealed,
            isFalse,
            reason:
                'Cue $i (active=$activeIndex) must stay blurred; the '
                'active cue has no privileged reveal state.',
          );
        }
      }
    },
  );
}
