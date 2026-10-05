@Tags(['gallery'])
library;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/application/transport_slider_position_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fixtures.dart';
import '../support/fake_player_engine.dart';
import 'gallery_support.dart';

const _mediaId = 'm1';

class _SessionController extends PlayerController {
  @override
  PlaybackSession? build() {
    final now = DateTime(2026, 1, 1);
    return PlaybackSession(
      mediaId: _mediaId,
      dexieTargetType: 'Audio',
      mediaType: 'audio',
      mediaTitle: 'The missing ingredient in how we learn',
      durationSeconds: 349,
      currentTimeSeconds: 78,
      currentSegmentIndex: 3,
      language: 'en',
      startedAt: now,
      lastActiveAt: now,
    );
  }
}

final _lines = [
  for (final (i, text) in [
    'In the early 1900s, an Italian doctor noticed something remarkable.',
    'Children who were given the freedom to choose their own activities',
    'became deeply absorbed in their work for long stretches of time.',
    'and they’ve taken a variety of approaches',
    'to keep this kind of self-directed learning alive.',
    'In his kindergartens, Friedrich Fröbel built toys',
    'that invited children to discover shapes on their own.',
    'What they all share is a simple idea:',
    'curiosity grows when we are trusted to follow it.',
  ].indexed)
    TranscriptLine(text: text, startMs: 60000 + i * 4200, durationMs: 3900),
];

class _EchoActive extends EchoMode {
  @override
  EchoState build() => const EchoState(
    active: true,
    startLineIndex: 4,
    endLineIndex: 4,
    startTimeSeconds: 76.8,
    endTimeSeconds: 80.7,
  );
}

List<Override> _listenOverrides(
  AppDatabase db,
  FakePlayerEngine engine, {
  bool playing = true,
}) => [
  ...baseOverrides(db, playerController: _SessionController.new),
  playerEngineTestDoubleProvider.overrideWithValue(engine),
  transcriptHasLinesForMediaProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(true)),
  transcriptLinesForMediaProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(_lines)),
  playerIsPlayingProvider.overrideWith((ref) => Stream.value(playing)),
  displayPositionProvider.overrideWith(
    (ref) => Stream.value(const Duration(seconds: 73)),
  ),
  transportSliderPositionProvider.overrideWith(
    (ref) => Stream.value(const Duration(seconds: 73)),
  ),
  playerIsBufferingProvider.overrideWith((ref) => Stream.value(false)),
  allTranscriptsForMediaProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(const <TranscriptTrack>[])),
  transcriptFetchCtrlProvider(_mediaId).overrideWithValue(
    const TranscriptFetchUiState(status: TranscriptFetchStatus.idle),
  ),
  videoRowForMediaProvider(_mediaId).overrideWith(
    (ref) async => VideoRow(
      createdAt: DateTime.utc(2024),
      updatedAt: DateTime.utc(2024),
      id: _mediaId,
      vid: 'v1',
      provider: 'local',
      title: 'T',
      durationSeconds: 349,
      language: 'en',
    ),
  ),
];

List<Override> _echoOverrides(AppDatabase db, FakePlayerEngine engine) => [
  ..._listenOverrides(db, engine, playing: false),
  echoModeProvider.overrideWith(_EchoActive.new),
];

GoRouter _listenRouter() => GoRouter(
  initialLocation: '/player/$_mediaId',
  routes: [
    ShellRoute(
      builder: (context, state, child) => RootShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/player/:id',
          builder: (_, _) => const TranscriptPanel(mediaId: _mediaId),
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(setUpGallery);

  testWidgets('Main — player Listen, desktop light', (tester) async {
    await _shootListen(tester, 'Main', Brightness.light, GalleryFrame.desktop);
  });

  testWidgets('DDark — player Listen, desktop dark', (tester) async {
    await _shootListen(tester, 'DDark', Brightness.dark, GalleryFrame.desktop);
  });

  testWidgets('DCompact — player Listen, compact light', (tester) async {
    await _shootListen(
      tester,
      'DCompact',
      Brightness.light,
      GalleryFrame.compact,
    );
  });

  testWidgets('DEcho — player Echo, desktop light', (tester) async {
    final db = memoryDb();
    final engine = FakePlayerEngine();
    addTearDown(engine.dispose);
    await shootBoard(
      tester,
      'DEcho',
      sceneApp(
        router: _listenRouter(),
        overrides: _echoOverrides(db, engine),
        brightness: Brightness.light,
      ),
      frame: GalleryFrame.desktop,
      db: db,
    );
  });
}

Future<void> _shootListen(
  WidgetTester tester,
  String board,
  Brightness brightness,
  GalleryFrame frame,
) async {
  final db = memoryDb();
  final engine = FakePlayerEngine();
  addTearDown(engine.dispose);
  await shootBoard(
    tester,
    board,
    sceneApp(
      router: _listenRouter(),
      overrides: _listenOverrides(db, engine),
      brightness: brightness,
    ),
    frame: frame,
    db: db,
  );
}
