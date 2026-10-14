import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_display_readiness.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_display_readiness_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _mediaId = 'actions-media';
final _epoch = DateTime.utc(2026);

class _Session extends PlayerController {
  _Session(this.targetType);

  final String targetType;

  @override
  PlaybackSession? build() => PlaybackSession(
    mediaId: _mediaId,
    dexieTargetType: targetType,
    mediaType: targetType.toLowerCase(),
    mediaTitle: 'Actions',
    durationSeconds: 60,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: _epoch,
    lastActiveAt: _epoch,
  );
}

TranscriptDisplayReadiness _readiness({
  required bool showEnrich,
  bool trusted = true,
}) => TranscriptDisplayReadiness(
  hasNestedWords: false,
  hasTimedWords: false,
  hasPhones: false,
  canTrustWordTimes: trusted,
  karaokeSwitchEnabled: false,
  ipaSwitchEnabled: false,
  showEnrich: showEnrich,
);

const _aiTrack = TranscriptTrack(
  id: 'ai',
  targetType: 'Video',
  targetId: _mediaId,
  language: 'en',
  source: 'ai',
  label: 'AI',
  trackIndex: null,
);

Future<List<TranscriptAction>> _actions(
  WidgetTester tester, {
  String targetType = 'Video',
  String? provider = 'local',
  List<TranscriptTrack> tracks = const [],
  List<TranscriptLine> lines = const [],
  TranscriptDisplayReadiness? readiness,
  TranscriptEnrichmentState enrich = const TranscriptEnrichmentState.idle(),
}) async {
  late List<TranscriptAction> actions;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerControllerProvider.overrideWith(() => _Session(targetType)),
        videoRowForMediaProvider(_mediaId).overrideWith(
          (ref) async => provider == null
              ? null
              : VideoRow(
                  createdAt: _epoch,
                  updatedAt: _epoch,
                  id: _mediaId,
                  vid: 'v',
                  provider: provider,
                  title: 'Actions',
                  durationSeconds: 60,
                  language: 'en',
                ),
        ),
        allTranscriptsForMediaProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value(tracks)),
        transcriptLinesForMediaProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value(lines)),
        transcriptDisplayReadinessForMediaProvider(
          _mediaId,
        ).overrideWithValue(readiness ?? _readiness(showEnrich: false)),
        transcriptEnrichmentControllerProvider(
          _mediaId,
        ).overrideWithValue(enrich),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            actions = watchTranscriptActions(
              ref,
              AppLocalizations.of(context)!,
              _mediaId,
            );
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return actions;
}

void main() {
  testWidgets('local video with a track offers edit first, in menu order', (
    tester,
  ) async {
    final actions = await _actions(
      tester,
      tracks: const [_aiTrack],
      lines: const [TranscriptLine(text: 'Hi', startMs: 0, durationMs: 500)],
      readiness: _readiness(showEnrich: true),
    );

    expect(actions.map((a) => a.kind), [
      TranscriptActionKind.edit,
      TranscriptActionKind.importFile,
      TranscriptActionKind.embeddedSubtitles,
      TranscriptActionKind.aiTranscript,
      TranscriptActionKind.wordTimings,
      TranscriptActionKind.refreshCloud,
      TranscriptActionKind.downloadTranscript,
    ]);
    expect(actions.first.label, 'Edit transcript');
    expect(actions[3].label, 'Transcribe again…');
    expect(actions[4].label, 'Add word timings & IPA');
    expect(actions.last.label, 'Download transcript…');
  });

  testWidgets('no transcript track means no edit entry', (tester) async {
    final actions = await _actions(
      tester,
      readiness: _readiness(showEnrich: true),
    );

    expect(
      actions.map((a) => a.kind),
      isNot(contains(TranscriptActionKind.edit)),
    );
  });

  testWidgets('download drops out when no primary transcript is active', (
    tester,
  ) async {
    final actions = await _actions(tester, tracks: const [_aiTrack]);

    expect(
      actions.map((a) => a.kind),
      isNot(contains(TranscriptActionKind.downloadTranscript)),
    );
  });

  testWidgets('download survives on YouTube when lines exist', (tester) async {
    final actions = await _actions(
      tester,
      provider: 'youtube',
      lines: const [TranscriptLine(text: 'Hi', startMs: 0, durationMs: 500)],
    );

    expect(
      actions.map((a) => a.kind),
      contains(TranscriptActionKind.downloadTranscript),
    );
  });

  testWidgets('audio has no embedded subtitles; first AI run says Create', (
    tester,
  ) async {
    final actions = await _actions(tester, targetType: 'Audio', provider: null);

    expect(
      actions.map((a) => a.kind),
      isNot(contains(TranscriptActionKind.embeddedSubtitles)),
    );
    expect(
      actions.map((a) => a.kind),
      isNot(contains(TranscriptActionKind.edit)),
    );
    expect(
      actions
          .firstWhere((a) => a.kind == TranscriptActionKind.aiTranscript)
          .label,
      'Create an AI transcript…',
    );
  });

  testWidgets('YouTube keeps only pronunciation and cloud refresh', (
    tester,
  ) async {
    final actions = await _actions(
      tester,
      provider: 'youtube',
      readiness: _readiness(showEnrich: true, trusted: false),
    );

    expect(actions.map((a) => a.kind), [
      TranscriptActionKind.wordTimings,
      TranscriptActionKind.refreshCloud,
    ]);
    expect(actions.first.label, 'Add pronunciation (IPA)');
  });

  testWidgets('word timings drop out while they are generating', (
    tester,
  ) async {
    final actions = await _actions(
      tester,
      readiness: _readiness(showEnrich: true),
      enrich: const TranscriptEnrichmentState.running(completed: 1, total: 9),
    );

    expect(
      actions.map((a) => a.kind),
      isNot(contains(TranscriptActionKind.wordTimings)),
    );
  });
}
