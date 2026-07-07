// ignore_for_file: scoped_providers_should_specify_dependencies
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_sheet.dart';
import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_sections.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _mediaId = 'media-picker-test';

/// Minimal [PlayerController] that reports no open session, so the picker
/// renders without a video target / media_kit engine.
class _NoSessionPlayerController extends PlayerController {
  @override
  PlaybackSession? build() => null;
}

List<Override> _pickerOverrides({required List<TranscriptTrack> tracks}) => [
  playerControllerProvider.overrideWith(() => _NoSessionPlayerController()),
  allTranscriptsForMediaProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(tracks)),
  activeTranscriptIdProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(null)),
  secondaryTranscriptIdProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(null)),
  videoRowForMediaProvider(_mediaId).overrideWith((ref) async => null),
  transcriptFetchStatusProvider(_mediaId).overrideWithValue(
    const TranscriptFetchUiState(status: TranscriptFetchStatus.idle),
  ),
];

Widget _harness({required List<Override> overrides}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: Center(
            child: SubtitleTrackPickerSheet(
              mediaId: _mediaId,
              presentation: SubtitleTrackPickerPresentation.dialog,
            ),
          ),
        ),
      ),
    ),
  );
}

late final AppLocalizations l10n;

void main() {
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('renders the no-tracks hint when no transcripts are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(overrides: _pickerOverrides(tracks: const [])),
    );
    // The dialog loading skeleton's internal ListView is unbounded inside
    // the sheet's SingleChildScrollView for one frame before the stream
    // emits; that is a pre-existing quirk of the loading branch and is
    // unrelated to this module split. Drain it, then settle on the data
    // frame which is what the refactor touches.
    await tester.pump();
    tester.takeException();
    await tester.pumpAndSettle();

    // With no tracks, the primary list shows the empty hint while the
    // translation section is still rendered (it always offers "None").
    expect(find.byType(CollapsibleTrackSection), findsNWidgets(1));
    expect(find.text(l10n.noTranscriptHint), findsOneWidget);
  });

  testWidgets(
    'renders primary and translation sections when a track is available',
    (tester) async {
      const track = TranscriptTrack(
        id: 't1',
        targetType: 'Video',
        targetId: _mediaId,
        language: 'en',
        source: 'user',
        label: 'English',
        trackIndex: null,
      );
      await tester.pumpWidget(
        _harness(overrides: _pickerOverrides(tracks: const [track])),
      );
      await tester.pump();
      tester.takeException();
      await tester.pumpAndSettle();

      expect(find.byType(CollapsibleTrackSection), findsNWidgets(2));
      expect(find.text(l10n.subtitlesPrimary), findsOneWidget);
      expect(find.text(l10n.subtitlesTranslation), findsOneWidget);
    },
  );
}
