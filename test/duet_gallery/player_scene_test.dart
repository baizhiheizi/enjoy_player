@Tags(['gallery'])
library;

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:enjoy_player/core/audio/recording_preview_player.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/application/transport_slider_position_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_widgets.dart';
import 'package:enjoy_player/features/player/presentation/root_shell.dart';
import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/features/share_poster/presentation/practice_poster_preview_sheet.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_margin.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fixtures.dart';
import '../support/fake_player_engine.dart';
import 'gallery_support.dart';

const _mediaId = 'm1';
const _activeLine = 5;

class _SessionController extends PlayerController {
  @override
  PlaybackSession? build() {
    final now = DateTime(2026, 1, 1);
    return PlaybackSession(
      mediaId: _mediaId,
      dexieTargetType: 'Audio',
      mediaType: 'audio',
      mediaTitle: 'The Ferry at Six',
      durationSeconds: 55,
      currentTimeSeconds: 22,
      currentSegmentIndex: _activeLine,
      language: 'en',
      startedAt: now,
      lastActiveAt: now,
    );
  }
}

const _board = [
  (
    'Every morning at six, the ferry leaves before the city wakes up.',
    '每天早上六点，渡轮总在城市醒来之前出发。',
    4400,
  ),
  (
    'I started taking it last spring, mostly by accident.',
    '我是去年春天开始坐渡轮的，多半是出于偶然。',
    3900,
  ),
  (
    'My usual train was cancelled, and the ferry was the only way across.',
    '我常坐的那班火车停运了，渡轮是唯一能过河的办法。',
    4600,
  ),
  (
    'The first thing I noticed was how quiet everyone was.',
    '我注意到的第一件事，是大家有多安静。',
    3600,
  ),
  (
    'Nobody was on their phone; they were just watching the water.',
    '没有人在看手机，他们只是望着水面。',
    4400,
  ),
  (
    "You don't take the ferry to save time; you take it to slow down.",
    '坐渡轮不是为了省时间，而是为了慢下来。',
    4200,
  ),
  (
    'By the second week, I knew the faces of the regulars.',
    '到了第二周，我已经认得那些常客的脸了。',
    4100,
  ),
  (
    'The man with the thermos always offered me a cup.',
    '那个带保温瓶的男人总会请我喝一杯。',
    3700,
  ),
  ('We never talked much, but we always nodded.', '我们从不多聊，但总会点点头。', 3300),
  (
    'Somewhere in the middle of the river, the sun comes up behind the bridge.',
    '船行到河中央时，太阳从桥后升起。',
    4800,
  ),
  ('For about a minute, the whole boat goes gold.', '大约有一分钟，整条船都被染成金色。', 3400),
  (
    "Then the engines change their sound, and we're almost there.",
    '接着引擎的声音变了，我们快到了。',
    4300,
  ),
  ("I could take the train again now, but I don't.", '我现在又可以坐火车了，但我没有。', 3500),
  ('Some mornings are worth the long way around.', '有些早晨，值得绕远路。', 3600),
];

const _loopIpa = [
  ('You', 'juː'),
  ("don't", 'doʊnt'),
  ('take', 'teɪk'),
  ('the', 'ðə'),
  ('ferry', 'ˈfɛri'),
  ('to', 'tə'),
  ('save', 'seɪv'),
  ('time;', 'taɪm'),
  ('you', 'juː'),
  ('take', 'teɪk'),
  ('it', 'ɪt'),
  ('to', 'tə'),
  ('slow', 'sloʊ'),
  ('down.', 'daʊn'),
];

int _startMs(int index) =>
    _board.take(index).fold(0, (sum, line) => sum + line.$3);

List<TranscriptWord>? _timeline(int index) {
  if (index != _activeLine) return null;
  final start = _startMs(index);
  final step = _board[index].$3 ~/ _loopIpa.length;
  return [
    for (final (i, (word, ipa)) in _loopIpa.indexed)
      TranscriptWord(
        text: word,
        startMs: start + i * step,
        durationMs: step,
        phones: [TranscriptPhone(phone: ipa, text: ipa)],
      ),
  ];
}

final _lines = [
  for (final (i, line) in _board.indexed)
    TranscriptLine(
      text: line.$1,
      startMs: _startMs(i),
      durationMs: line.$3,
      timeline: _timeline(i),
    ),
];

final _translations = [
  for (final (i, line) in _board.indexed)
    TranscriptLine(text: line.$2, startMs: _startMs(i), durationMs: line.$3),
];

class _EchoActive extends EchoMode {
  @override
  EchoState build() => EchoState(
    active: true,
    startLineIndex: _activeLine,
    endLineIndex: _activeLine,
    startTimeSeconds: _startMs(_activeLine) / 1000,
    endTimeSeconds: (_startMs(_activeLine) + _board[_activeLine].$3) / 1000,
  );
}

class _SilentPreview implements RecordingPreviewPlayback {
  @override
  String? loadedPath;

  @override
  Stream<bool> get playing => const Stream.empty();

  @override
  Stream<Duration> get position => const Stream.empty();

  @override
  Stream<Duration> get duration => const Stream.empty();

  @override
  Future<void> play(String path) async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> playClip(String path, Duration start, Duration end) async {}

  @override
  Future<void> playOrPauseTake(String path) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _IpaOn extends IpaOverlaySettings {
  @override
  Future<bool> build() async => true;
}

Future<void> _seedTakes(AppDatabase db) async {
  final start = _startMs(_activeLine);
  final now = DateTime(2026, 10, 1, 12);
  for (final (n, durationMs, score) in [
    (1, 3900, null),
    (2, 4600, 71),
    (3, 4000, 84),
  ]) {
    await db
        .into(db.recordings)
        .insert(
          RecordingsCompanion.insert(
            createdAt: now.add(Duration(minutes: n)),
            updatedAt: now.add(Duration(minutes: n)),
            id: 'take-$n',
            targetType: 'Audio',
            targetId: _mediaId,
            referenceStart: start,
            referenceDuration: _board[_activeLine].$3,
            referenceText: _board[_activeLine].$1,
            language: 'en',
            duration: durationMs,
            pronunciationScore: Value(score),
            localPath: Value('/tmp/take-$n.wav'),
          ),
        );
  }
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
    (ref) => Stream.value(const Duration(seconds: 22)),
  ),
  transportSliderPositionProvider.overrideWith(
    (ref) => Stream.value(const Duration(seconds: 22)),
  ),
  secondaryTranscriptLinesForMediaProvider(
    _mediaId,
  ).overrideWith((ref) => Stream.value(_translations)),
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
      title: 'The Ferry at Six',
      durationSeconds: 55,
      language: 'en',
    ),
  ),
];

List<Override> _echoOverrides(
  AppDatabase db,
  FakePlayerEngine engine, {
  bool ipa = false,
}) => [
  ..._listenOverrides(db, engine, playing: false),
  echoModeProvider.overrideWith(_EchoActive.new),
  recordingPreviewPlayerProvider.overrideWithValue(_SilentPreview()),
  if (ipa) ipaOverlaySettingsProvider.overrideWith(_IpaOn.new),
];

var openPosterOnNextMount = false;
var openAssessmentOnNextMount = false;

GoRouter _playerRouter() => GoRouter(
  initialLocation: '/player/$_mediaId',
  routes: [
    ShellRoute(
      builder: (context, state, child) => RootShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/player/:id',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              final chrome = ref.watch(
                playerControllerProvider.select(playbackChromeOf),
              );
              final body = chrome == null
                  ? const SizedBox.shrink()
                  : ExpandedPlayerChromeBody(mediaId: _mediaId, chrome: chrome);
              if (openAssessmentOnNextMount) {
                openAssessmentOnNextMount = false;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!context.mounted) return;
                  await showAssessmentMargin(
                    context: context,
                    assessment: _boardAssessment(),
                  );
                });
              }
              if (openPosterOnNextMount) {
                openPosterOnNextMount = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  unawaited(
                    showPracticePosterPreviewSheet(
                      context,
                      ref,
                      mediaId: _mediaId,
                    ),
                  );
                });
              }
              return body;
            },
          ),
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(setUpGallery);

  for (final (board, frame, brightness, echo, ipa) in [
    ('Main', GalleryFrame.desktop, Brightness.light, false, false),
    ('DDark', GalleryFrame.desktop, Brightness.dark, false, false),
    ('DEcho', GalleryFrame.desktop, Brightness.light, true, true),
    ('DCompact', GalleryFrame.compact, Brightness.light, true, false),
    ('Phone', GalleryFrame.phone, Brightness.light, false, false),
    ('PEcho', GalleryFrame.phone, Brightness.light, true, false),
    ('PDark', GalleryFrame.phone, Brightness.dark, true, false),
    ('Poster', GalleryFrame.desktop, Brightness.light, true, false),
    ('DScored', GalleryFrame.desktop, Brightness.light, true, false),
  ]) {
    testWidgets(board, (tester) async {
      final db = memoryDb();
      final engine = FakePlayerEngine();
      addTearDown(engine.dispose);
      await tester.runAsync(() => _seedTakes(db));
      openPosterOnNextMount = board == 'Poster';
      openAssessmentOnNextMount = board == 'DScored';
      await shootBoard(
        tester,
        board,
        sceneApp(
          router: _playerRouter(),
          overrides: echo
              ? _echoOverrides(db, engine, ipa: ipa)
              : _listenOverrides(db, engine, playing: false),
          brightness: brightness,
        ),
        frame: frame,
        db: db,
        before: null,
      );
    });
  }
}

AzurePronunciationAssessmentResult _boardAssessment() {
  const word = AzureWordAssessment(
    word: 'ferry',
    offset: 0,
    duration: 4000000,
    pronunciationAssessment: AzureWordPronunciationAssessment(
      accuracyScore: 72,
      errorType: 'Mispronunciation',
    ),
  );
  const good = AzureWordAssessment(
    word: 'slow',
    offset: 0,
    duration: 3000000,
    pronunciationAssessment: AzureWordPronunciationAssessment(
      accuracyScore: 95,
      errorType: 'None',
    ),
  );
  return AzurePronunciationAssessmentResult(
    recognitionStatus: 'Success',
    offset: 0,
    duration: 4200000,
    displayText: _board[_activeLine].$1,
    nBest: [
      AzureNBestResult(
        confidence: 0.9,
        lexical: _board[_activeLine].$1,
        itn: _board[_activeLine].$1,
        maskedItn: _board[_activeLine].$1,
        display: _board[_activeLine].$1,
        pronunciationAssessment: const AzurePronunciationAssessmentScores(
          accuracyScore: 82,
          fluencyScore: 78,
          completenessScore: 100,
          pronScore: 84,
          prosodyScore: 75,
        ),
        words: [word, good],
      ),
    ],
  );
}
