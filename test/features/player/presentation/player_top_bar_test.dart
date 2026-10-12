import 'package:drift/native.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_top_bar.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'bar-media';
final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

class _SessionPlayerController extends PlayerController {
  @override
  PlaybackSession? build() => PlaybackSession(
    mediaId: _mediaId,
    dexieTargetType: 'Video',
    mediaType: 'video',
    mediaTitle: 'Bar media',
    durationSeconds: 120,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: _epoch,
    lastActiveAt: _epoch,
  );
}

List<Override> _overrides() {
  final db = AppDatabase(executor: NativeDatabase.memory());
  return [
    appDatabaseProvider.overrideWithValue(db),
    deviceGlobalAppDatabaseProvider.overrideWithValue(db),
    playerControllerProvider.overrideWith(_SessionPlayerController.new),
    transcriptPlaybackHighlightProvider(
      _mediaId,
    ).overrideWith((ref) => (cueIndex: 2, wordIndex: null)),
    transcriptLinesForMediaProvider(_mediaId).overrideWith(
      (ref) => Stream.value(
        List.generate(
          5,
          (i) => TranscriptLine(
            text: 'Line $i',
            startMs: i * 1000,
            durationMs: 1000,
          ),
        ),
      ),
    ),
  ];
}

Future<void> _pumpBar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SizedBox(width: 360, child: PlayerTopBar(mediaId: _mediaId)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('echo shortcut chip renders only on desktop platforms', () {
    expect(echoModeShortcutVisible(), isDesktop);
  });

  testWidgets('phone header holds the title row only, never a cue caption', (
    tester,
  ) async {
    await _pumpBar(tester);

    expect(find.text('Bar media'), findsOneWidget);
    expect(find.textContaining('Line 3 of 5'), findsNothing);
  });
}
