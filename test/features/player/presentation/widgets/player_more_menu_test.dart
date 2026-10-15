import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_display_readiness.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_availability.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_more_menu.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_display_readiness_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_controller.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _mediaId = 'more-menu-media';
final _epoch = DateTime.utc(2026);
const _exportRowKey = ValueKey('player-more-export-loop-clip');

class _Session extends PlayerController {
  @override
  PlaybackSession? build() => PlaybackSession(
    mediaId: _mediaId,
    dexieTargetType: 'Audio',
    mediaType: 'audio',
    mediaTitle: 'More menu',
    durationSeconds: 60,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: _epoch,
    lastActiveAt: _epoch,
  );
}

Future<(PlayerMoreMenuPanel, List<PlayerMenuChoice>)> _pump(
  WidgetTester tester, {
  required bool exportAvailable,
}) async {
  final choices = <PlayerMenuChoice>[];
  final panel = PlayerMoreMenuPanel(mediaId: _mediaId, onChoose: choices.add);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerControllerProvider.overrideWith(() => _Session()),
        videoRowForMediaProvider(_mediaId).overrideWith((ref) async => null),
        allTranscriptsForMediaProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value(const [])),
        transcriptDisplayReadinessForMediaProvider(_mediaId).overrideWithValue(
          const TranscriptDisplayReadiness(
            hasNestedWords: false,
            hasTimedWords: false,
            hasPhones: false,
            canTrustWordTimes: false,
            karaokeSwitchEnabled: false,
            ipaSwitchEnabled: false,
            showEnrich: false,
          ),
        ),
        transcriptEnrichmentControllerProvider(
          _mediaId,
        ).overrideWithValue(const TranscriptEnrichmentState.idle()),
        loopClipExportAvailableProvider(
          _mediaId,
        ).overrideWith((ref) async => exportAvailable),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: panel)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (panel, choices);
}

void main() {
  testWidgets(
    'Media group shows the export entry between transcript rows and shortcuts',
    (tester) async {
      await _pump(tester, exportAvailable: true);

      expect(find.text('MEDIA'), findsOneWidget);
      expect(find.text('Export the loop as a clip…'), findsOneWidget);

      final rows = tester
          .widgetList<PlayerMenuRow>(find.byType(PlayerMenuRow))
          .toList();
      final keys = rows.map((r) => r.key).toList();
      expect(keys, contains(const ValueKey('transcript-action-refreshCloud')));
      expect(
        keys.indexOf(const ValueKey('transcript-action-refreshCloud')),
        lessThan(keys.indexOf(_exportRowKey)),
      );
      expect(
        keys.indexOf(_exportRowKey),
        lessThan(keys.indexOf(const ValueKey('player-more-shortcuts'))),
      );
    },
  );

  testWidgets('export entry is enabled when a loop and a direct source exist', (
    tester,
  ) async {
    await _pump(tester, exportAvailable: true);

    final row = tester.widget<PlayerMenuRow>(find.byKey(_exportRowKey));
    expect(row.enabled, isTrue);
  });

  testWidgets(
    'export entry is disabled without an exportable loop and source',
    (tester) async {
      final (_, choices) = await _pump(tester, exportAvailable: false);

      final row = tester.widget<PlayerMenuRow>(find.byKey(_exportRowKey));
      expect(row.enabled, isFalse);

      await tester.tap(find.text('Export the loop as a clip…'));
      await tester.pump();
      expect(choices, isEmpty);
    },
  );

  testWidgets('tapping the enabled export entry chooses the clip export', (
    tester,
  ) async {
    final (_, choices) = await _pump(tester, exportAvailable: true);

    await tester.tap(find.text('Export the loop as a clip…'));
    await tester.pump();
    expect(choices, hasLength(1));
  });
}
