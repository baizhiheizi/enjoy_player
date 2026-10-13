import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/transcript_display_readiness.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/settings/application/transcript_typeface_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_controller.dart';
import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_primitives.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_display_settings_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../helpers/transcript_settings_overrides.dart';

class _SpyKaraoke extends KaraokeHighlightSettingsOverride {
  _SpyKaraoke(super.enabled);

  var writes = 0;

  @override
  Future<void> setEnabled(bool enabled) async {
    writes += 1;
    await super.setEnabled(enabled);
  }
}

Widget _harness({
  required TranscriptDisplayReadiness readiness,
  required KaraokeHighlightSettings karaoke,
  List<Override> extraOverrides = const [],
  bool actionsBelow = false,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return ProviderScope(
    overrides: [
      karaokeHighlightSettingsProvider.overrideWith(() => karaoke),
      ...transcriptIpaOverlayOffOverrides(),
      transcriptTypefaceSettingsProvider.overrideWith(
        TranscriptTypefaceSettingsOverride.new,
      ),
      ...extraOverrides,
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TranscriptDisplaySettingsSection(
          mediaId: 'media-gating',
          readiness: readiness,
          actionsBelow: actionsBelow,
        ),
      ),
    ),
  );
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  const lineOnly = TranscriptDisplayReadiness(
    hasNestedWords: false,
    hasTimedWords: false,
    hasPhones: false,
    canTrustWordTimes: true,
    karaokeSwitchEnabled: false,
    ipaSwitchEnabled: false,
    showEnrich: true,
  );

  testWidgets('line-only disables highlight and IPA and points to ⋯ More', (
    tester,
  ) async {
    final karaoke = _SpyKaraoke(true);
    await tester.pumpWidget(_harness(karaoke: karaoke, readiness: lineOnly));
    await tester.pumpAndSettle();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches[0].onChanged, isNull);
    expect(switches[1].onChanged, isNull);
    expect(find.text(l10n.subtitlesNeedsWordTimingsMore), findsNWidgets(2));
    expect(find.byType(TranscriptEnrichmentCard), findsNothing);

    await tester.tap(find.byType(SubtitleToggleTile).first);
    await tester.pump();
    expect(karaoke.writes, 0);
  });

  testWidgets('phone sheet points the hint at the actions below', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(false),
        readiness: lineOnly,
        actionsBelow: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.subtitlesNeedsWordTimingsBelow), findsNWidgets(2));
  });

  testWidgets('the panel has no Hide text switch (Dictate lens owns it)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(false),
        readiness: lineOnly,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.transcriptBlurDisplayTitle), findsNothing);
  });

  testWidgets('Book / Clean writes the transcript typeface', (tester) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(false),
        readiness: lineOnly,
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TranscriptDisplaySettingsSection)),
    );
    expect(
      container.read(transcriptTypefaceSettingsProvider).value,
      TranscriptTypeface.book,
    );

    await tester.tap(find.byKey(const ValueKey('typeface-clean')));
    await tester.pumpAndSettle();
    expect(
      container.read(transcriptTypefaceSettingsProvider).value,
      TranscriptTypeface.clean,
    );
  });

  testWidgets('timed+phones+owned enables both switches, no enrich card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(true),
        readiness: const TranscriptDisplayReadiness(
          hasNestedWords: true,
          hasTimedWords: true,
          hasPhones: true,
          canTrustWordTimes: true,
          karaokeSwitchEnabled: true,
          ipaSwitchEnabled: true,
          showEnrich: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches[0].onChanged, isNotNull);
    expect(switches[0].value, isTrue);
    expect(find.text(l10n.subtitlesHighlightSpokenWordHint), findsOneWidget);
    expect(find.byType(TranscriptEnrichmentCard), findsNothing);
  });

  testWidgets('untrusted word times explain highlight is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(false),
        readiness: const TranscriptDisplayReadiness(
          hasNestedWords: false,
          hasTimedWords: false,
          hasPhones: false,
          canTrustWordTimes: false,
          karaokeSwitchEnabled: false,
          ipaSwitchEnabled: false,
          showEnrich: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.transcriptKaraokeUnavailableRemoteHint),
      findsOneWidget,
    );
  });

  testWidgets('running enrichment shows a progress card with Cancel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(false),
        extraOverrides: [
          transcriptEnrichmentControllerProvider(
            'media-gating',
          ).overrideWithValue(
            const TranscriptEnrichmentState.running(completed: 12, total: 240),
          ),
        ],
        readiness: lineOnly,
      ),
    );
    await tester.pump();

    expect(find.text(l10n.transcriptEnrichRunningOwned), findsOneWidget);
    expect(find.text(l10n.transcriptEnrichCancel), findsOneWidget);
    expect(find.text(l10n.transcriptEnrichProgress(12, 240)), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('failed enrichment offers a retry', (tester) async {
    await tester.pumpWidget(
      _harness(
        karaoke: KaraokeHighlightSettingsOverride(false),
        extraOverrides: [
          transcriptEnrichmentControllerProvider(
            'media-gating',
          ).overrideWithValue(const TranscriptEnrichmentState.failed('empty')),
        ],
        readiness: lineOnly,
      ),
    );
    await tester.pump();

    expect(find.text(l10n.transcriptEnrichFailed), findsOneWidget);
    expect(find.text(l10n.transcriptEnrichRetry), findsOneWidget);
  });
}
