import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../helpers/transcript_settings_overrides.dart';

Widget transcriptTileHarness(Widget child) {
  return ProviderScope(
    overrides: [
      transcriptBlurModeProvider.overrideWith(() => _BlurMode(false)),
      karaokeHighlightSettingsProvider.overrideWith(_KaraokeHighlightOff.new),
      ...transcriptWordPracticeOffOverrides(),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

class _BlurMode extends TranscriptBlurMode {
  _BlurMode(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

class _KaraokeHighlightOff extends KaraokeHighlightSettings {
  @override
  Future<bool> build() async => false;
}

TranscriptLineTile tile({VoidCallback? onRetranslate}) => TranscriptLineTile(
  line: const TranscriptLine(text: 'Hello world', startMs: 0, durationMs: 2000),
  mediaId: 'test',
  secondaryText: '你好世界',
  isActive: true,
  inEcho: false,
  groupedInEcho: false,
  selectable: false,
  onRetranslateSecondary: onRetranslate,
  onTap: () {},
);

void main() {
  testWidgets('retranslate affordance renders inline and taps', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    var calls = 0;
    await tester.pumpWidget(
      transcriptTileHarness(tile(onRetranslate: () => calls++)),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == l10n.subtitlesAutoTranslateRetranslateLine,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(EnjoyIcons.refresh), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    await tester.tap(find.byIcon(EnjoyIcons.refresh));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('no retranslate callback renders no affordance', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(transcriptTileHarness(tile()));

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == l10n.subtitlesAutoTranslateRetranslateLine,
      ),
      findsNothing,
    );
    expect(find.byIcon(EnjoyIcons.refresh), findsNothing);
  });
}
