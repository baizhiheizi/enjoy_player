import 'package:drift/native.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_lens.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_more_menu.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_top_bar.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'bar-media';
final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

const _menuTrack = TranscriptTrack(
  id: 'bar-transcript',
  targetType: 'Video',
  targetId: _mediaId,
  language: 'en',
  source: 'user',
  label: 'EN',
  trackIndex: null,
);

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

class _SpyInteractions extends PlayerInteractions {
  _SpyInteractions(super.ref);

  final selected = <PlayerLens>[];

  @override
  Future<void> selectLens(PlayerLens lens) async => selected.add(lens);
}

_SpyInteractions? _spy;

List<Override> _overrides({AppDatabase? db}) {
  final database = db ?? AppDatabase(executor: NativeDatabase.memory());
  return [
    appDatabaseProvider.overrideWithValue(database),
    deviceGlobalAppDatabaseProvider.overrideWithValue(database),
    playerControllerProvider.overrideWith(_SessionPlayerController.new),
    playerInteractionsProvider.overrideWith(
      (ref) => _spy = _SpyInteractions(ref),
    ),
    transcriptPlaybackHighlightProvider(
      _mediaId,
    ).overrideWith((ref) => (cueIndex: 2, wordIndex: null)),
    transcriptHasLinesForMediaProvider(
      _mediaId,
    ).overrideWith((ref) => Stream.value(true)),
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

Future<void> _pumpBar(
  WidgetTester tester, {
  double width = 360,
  List<Override> overrides = const [],
  AppDatabase? db,
}) async {
  tester.view.physicalSize = width > 600
      ? const Size(1440, 900)
      : const Size(1080, 2400);
  tester.view.devicePixelRatio = width > 600 ? 1.0 : 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [..._overrides(db: db), ...overrides],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: const PlayerTopBar(mediaId: _mediaId),
            ),
          ),
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

  testWidgets('phone header has no ⋯ More (actions live in the sheet)', (
    tester,
  ) async {
    await _pumpBar(tester);

    expect(find.byKey(const ValueKey('player-top-bar-more')), findsNothing);
  });

  testWidgets('desktop bar ends with the Subtitles chip and ⋯ More', (
    tester,
  ) async {
    await _pumpBar(tester, width: 1200);

    expect(find.byKey(const ValueKey('player-top-bar-subtitles')), findsOne);
    expect(find.byKey(const ValueKey('player-top-bar-more')), findsOne);
    expect(
      tester.getCenter(find.byKey(const ValueKey('player-top-bar-more'))).dx,
      greaterThan(
        tester
            .getCenter(find.byKey(const ValueKey('player-top-bar-subtitles')))
            .dx,
      ),
    );
  });

  testWidgets('⋯ More opens the transcript menu and closes on outside tap', (
    tester,
  ) async {
    await _pumpBar(tester, width: 1200);

    await tester.tap(find.byKey(const ValueKey('player-top-bar-more')));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerMoreMenuPanel), findsOneWidget);
    expect(find.text('TRANSCRIPT'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transcript-action-refreshCloud')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('transcript-action-edit')), findsNothing);
    expect(
      find.byKey(const ValueKey('player-more-edit-details')),
      findsOneWidget,
    );
    expect(find.text('Keyboard shortcuts'), findsOneWidget);

    await tester.tapAt(const Offset(40, 600));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerMoreMenuPanel), findsNothing);
  });

  testWidgets('⋯ More lists Edit transcript first when a track exists', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      width: 1200,
      overrides: [
        allTranscriptsForMediaProvider(
          _mediaId,
        ).overrideWith((ref) => Stream.value(const [_menuTrack])),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('player-top-bar-more')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transcript-action-edit')),
      findsOneWidget,
    );
    expect(find.text('Edit transcript'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('transcript-action-edit')))
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('transcript-action-importFile')),
            )
            .dy,
      ),
    );
  });

  testWidgets('⋯ More groups Media under its own heading after Transcript', (
    tester,
  ) async {
    await _pumpBar(tester, width: 1200);

    await tester.tap(find.byKey(const ValueKey('player-top-bar-more')));
    await tester.pumpAndSettle();

    expect(find.text('MEDIA'), findsOneWidget);
    final transcriptDy = tester.getTopLeft(find.text('TRANSCRIPT')).dy;
    final mediaDy = tester.getTopLeft(find.text('MEDIA')).dy;
    final shortcutsDy = tester.getTopLeft(find.text('Keyboard shortcuts')).dy;
    expect(transcriptDy, lessThan(mediaDy));
    expect(mediaDy, lessThan(shortcutsDy));
  });

  testWidgets('Edit details opens prefilled for the open media', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.videoDao.insertRow(
      VideoRow(
        id: _mediaId,
        vid: 'vid-bar',
        provider: 'user',
        title: 'Bar media',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 120,
        language: 'en-US',
        source: null,
        localUri: null,
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _pumpBar(tester, width: 1200, db: db);

    await tester.tap(find.byKey(const ValueKey('player-top-bar-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-more-edit-details')));
    await tester.pumpAndSettle();

    expect(find.text('Edit details'), findsOneWidget);
    expect(find.text('English (US)'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Bar media');
  });

  testWidgets('Edit details for a missing row surfaces the missing notice', (
    tester,
  ) async {
    await _pumpBar(tester, width: 1200);

    await tester.tap(find.byKey(const ValueKey('player-top-bar-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-more-edit-details')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('This item is no longer in your library.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('desktop mode switch has Listen, Echo and Dictate', (
    tester,
  ) async {
    await _pumpBar(tester, width: 1200);

    for (final lens in PlayerLens.values) {
      expect(find.byKey(ValueKey('player-lens-${lens.name}')), findsOne);
    }
    expect(find.text('Dictate'), findsOneWidget);
    expect(find.text('H'), echoModeShortcutVisible() ? findsOne : findsNothing);
  });

  testWidgets('tapping Dictate selects the Dictate lens', (tester) async {
    await _pumpBar(tester, width: 1200);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('player-lens-dictate')));
    await tester.pump();

    expect(_spy!.selected, [PlayerLens.dictate]);
  });

  testWidgets('phone mode switch fits three lenses at 360 wide', (
    tester,
  ) async {
    await _pumpBar(tester);

    expect(find.byKey(const ValueKey('player-lens-dictate')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
