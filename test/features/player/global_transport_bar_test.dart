import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/global_transport_bar.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_progress_strip.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_player_engine.dart';

const _kMediaId = 'transport-bar-test';

PlaybackSession _testSession() {
  final now = DateTime(2026, 1, 1);
  return PlaybackSession(
    mediaId: _kMediaId,
    dexieTargetType: 'Audio',
    mediaType: 'audio',
    mediaTitle: 'Transport test',
    durationSeconds: 120,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: now,
    lastActiveAt: now,
  );
}

class _SessionPlayerController extends PlayerController {
  _SessionPlayerController(this._session);

  final PlaybackSession _session;

  @override
  PlaybackSession? build() => _session;
}

class _BlurMode extends TranscriptBlurMode {
  _BlurMode(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

Future<void> _seedTranscript(AppDatabase db) async {
  final now = DateTime(2026, 1, 1);
  const transcriptId = 'tr-transport';
  await db.audioDao.insertRow(
    AudioRow(
      id: _kMediaId,
      aid: 'f',
      provider: 'user',
      title: 't',
      description: null,
      thumbnailUrl: null,
      durationSeconds: 120,
      language: 'en',
      translationKey: null,
      sourceText: null,
      voice: null,
      source: null,
      localUri: 'file:///a.mp3',
      md5: null,
      size: 1,
      mediaUrl: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.transcriptDao.upsert(
    TranscriptRow(
      id: transcriptId,
      targetType: 'Audio',
      targetId: _kMediaId,
      language: 'en',
      source: 'user',
      timelineJson: jsonEncode([
        const TranscriptLine(text: 'hello', startMs: 0, durationMs: 1000)
            .toJson(),
      ]),
      referenceId: null,
      label: 'en',
      trackIndex: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.echoSessionDao.upsert(
    EchoSessionRow(
      id: 'echo-transport',
      targetType: 'Audio',
      targetId: _kMediaId,
      language: 'und',
      currentTimeMs: 0,
      playbackRate: 1,
      volume: 1,
      echoStartMs: null,
      echoEndMs: null,
      transcriptId: transcriptId,
      secondaryTranscriptId: null,
      recordingsCount: 0,
      recordingsDurationMs: 0,
      lastRecordingAt: null,
      currentSegmentIndex: -1,
      echoActive: false,
      echoStartLine: -1,
      echoEndLine: -1,
      blurActive: false,
      startedAt: now,
      lastActiveAt: now,
      completedAt: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

List<Override> _transportOverrides({
  required FakePlayerEngine fake,
  required AppDatabase db,
  bool hasLines = true,
  bool blurActive = false,
}) {
  return [
    appDatabaseProvider.overrideWithValue(db),
    playerEngineTestDoubleProvider.overrideWithValue(fake),
    playerControllerProvider.overrideWith(
      () => _SessionPlayerController(_testSession()),
    ),
    transcriptHasLinesForMediaProvider(
      _kMediaId,
    ).overrideWith((ref) => Stream.value(hasLines)),
    playerIsPlayingProvider.overrideWith((ref) => Stream.value(false)),
    playerIsBufferingProvider.overrideWith((ref) => Stream.value(false)),
    allTranscriptsForMediaProvider(
      _kMediaId,
    ).overrideWith((ref) => Stream.value(const <TranscriptTrack>[])),
    transcriptFetchCtrlProvider(_kMediaId).overrideWithValue(
      const TranscriptFetchUiState(status: TranscriptFetchStatus.idle),
    ),
    transcriptBlurModeProvider.overrideWith(() => _BlurMode(blurActive)),
  ];
}

Widget _transportHarness({
  required GoRouter router,
  required List<Override> overrides,
  required double width,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(width, 800)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}

GoRouter _playerRouter() {
  return GoRouter(
    initialLocation: '/player/$_kMediaId',
    routes: [
      GoRoute(
        path: '/player/:mediaId',
        builder: (_, _) => const Scaffold(
          bottomNavigationBar: GlobalTransportBar(),
          body: SizedBox.shrink(),
        ),
      ),
    ],
  );
}

GoRouter _libraryRouter() {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      GoRoute(
        path: '/library',
        builder: (_, _) => const Scaffold(
          bottomNavigationBar: GlobalTransportBar(),
          body: SizedBox.shrink(),
        ),
      ),
    ],
  );
}

/// Router with both shell and player routes so tap-to-expand navigation can be
/// observed via the body marker text.
GoRouter _expandableRouter() {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      GoRoute(
        path: '/library',
        builder: (_, _) => const Scaffold(
          bottomNavigationBar: GlobalTransportBar(),
          body: Center(child: Text('library-route')),
        ),
      ),
      GoRoute(
        path: '/player/:mediaId',
        builder: (_, _) => const Scaffold(
          bottomNavigationBar: GlobalTransportBar(),
          body: Center(child: Text('player-route')),
        ),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakePlayerEngine fake;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    fake = FakePlayerEngine();
  });

  tearDown(() async {
    await db.close();
    await fake.dispose();
  });

  Future<void> pumpTransport(
    WidgetTester tester, {
    required GoRouter router,
    required double width,
    bool hasLines = true,
    bool blurActive = false,
    bool seedTranscript = false,
  }) async {
    if (seedTranscript) {
      await _seedTranscript(db);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _transportHarness(
        router: router,
        overrides: _transportOverrides(
          fake: fake,
          db: db,
          hasLines: hasLines,
          blurActive: blurActive,
        ),
        width: width,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  // The always-on five controls (play, echo, blur, subtitle/cc, speed) must
  // be visible at the narrowest width on both routes — never clipped.
  const alwaysOnIcons = <IconData>[
    Icons.play_arrow_rounded, // play (not playing by default)
    Icons.mic_none_rounded, // echo
    Icons.visibility_outlined, // blur (off by default)
    Icons.closed_caption_outlined, // subtitle/cc
    Icons.speed_rounded, // speed
  ];

  group('GlobalTransportBar narrow always-on controls (US1)', () {
    testWidgets('player at 320px renders all five always-on controls', (
      tester,
    ) async {
      await pumpTransport(tester, router: _playerRouter(), width: 320);

      for (final icon in alwaysOnIcons) {
        expect(find.byIcon(icon), findsOneWidget, reason: '$icon visible');
      }
      expect(find.byIcon(Icons.replay_rounded), findsNothing);
    });

    testWidgets('mini at 320px renders all five always-on controls', (
      tester,
    ) async {
      await pumpTransport(tester, router: _libraryRouter(), width: 320);

      for (final icon in alwaysOnIcons) {
        expect(find.byIcon(icon), findsOneWidget, reason: '$icon visible');
      }
    });
  });

  group('GlobalTransportBar narrow drop sequence (US2)', () {
    // Inner width = device width - 2 * space12 (24). Budget thresholds:
    //   volume alone  -> 274 <= inner < 318
    //   volume + next -> 318 <= inner < 362
    //   + previous    -> 362 <= inner < 402
    testWidgets('mini at 320px drops previous and next, keeps volume', (
      tester,
    ) async {
      await pumpTransport(tester, router: _libraryRouter(), width: 320);

      expect(find.byIcon(Icons.skip_previous_rounded), findsNothing);
      expect(find.byIcon(Icons.skip_next_rounded), findsNothing);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('player at 375px drops previous, keeps next', (tester) async {
      await pumpTransport(tester, router: _playerRouter(), width: 375);

      expect(find.byIcon(Icons.skip_previous_rounded), findsNothing);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets('mini at 430px keeps previous and next', (tester) async {
      await pumpTransport(tester, router: _libraryRouter(), width: 430);

      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });
  });

  group('GlobalTransportBar collapsed expand (US3)', () {
    testWidgets('tapping neutral area expands mini at 320px', (tester) async {
      await pumpTransport(tester, router: _expandableRouter(), width: 320);

      // Expand icon is dropped at this width; only the tap zone can expand.
      expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);
      expect(find.text('library-route'), findsOneWidget);

      final spacer = find.descendant(
        of: find.byType(EnjoyTappableSurface),
        matching: find.byType(Spacer),
      );
      // The Spacer is empty space by design — its hit target is the parent
      // EnjoyTappableSurface, not itself — so silence the "would not hit test"
      // warning. Tapping here targets the neutral expand zone between the play
      // cluster and the trailing controls.
      await tester.tap(spacer, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('player-route'), findsOneWidget);
    });

    testWidgets('tapping play does not expand', (tester) async {
      await pumpTransport(tester, router: _expandableRouter(), width: 320);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(find.text('library-route'), findsOneWidget);
      expect(find.text('player-route'), findsNothing);
    });

    testWidgets('tapping a secondary control does not expand', (tester) async {
      await pumpTransport(tester, router: _expandableRouter(), width: 320);

      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('library-route'), findsOneWidget);
      expect(find.text('player-route'), findsNothing);
    });

    testWidgets('tapping the seek strip does not expand', (tester) async {
      await pumpTransport(tester, router: _expandableRouter(), width: 320);

      await tester.tap(find.byType(TransportProgressStrip));
      await tester.pumpAndSettle();

      expect(find.text('library-route'), findsOneWidget);
      expect(find.text('player-route'), findsNothing);
    });

    testWidgets('expand affordance is absent on the player route', (
      tester,
    ) async {
      await pumpTransport(tester, router: _playerRouter(), width: 320);

      // Already expanded -> no tap surface wrapping the controls row.
      expect(find.byType(EnjoyTappableSurface), findsNothing);
    });
  });

  group('GlobalTransportBar no-regression wide + affordance (US4)', () {
    testWidgets('wide mini renders full control set and meta-row expands', (
      tester,
    ) async {
      await pumpTransport(tester, router: _expandableRouter(), width: 800);

      // Full set present in wide layout.
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);

      // Meta-row tap target still opens the player (no regression).
      await tester.tap(find.text('Transport test'));
      await tester.pumpAndSettle();
      expect(find.text('player-route'), findsOneWidget);
    });

    testWidgets('collapsed narrow exposes the expand affordance surface', (
      tester,
    ) async {
      await pumpTransport(tester, router: _libraryRouter(), width: 320);
      expect(find.byType(EnjoyTappableSurface), findsOneWidget);
    });
  });

  group('GlobalTransportBar blur toggle', () {
    testWidgets('renders the blur toggle in off state', (tester) async {
      await pumpTransport(tester, router: _playerRouter(), width: 800);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('reflects on state with visibility_off icon', (tester) async {
      await pumpTransport(
        tester,
        router: _playerRouter(),
        width: 800,
        blurActive: true,
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('disabled when there are no transcript lines', (tester) async {
      await pumpTransport(
        tester,
        router: _playerRouter(),
        width: 800,
        hasLines: false,
      );
      final blurButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.visibility_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(blurButton.onPressed, isNull);
    });

    testWidgets('tap flips the blur enabled state', (tester) async {
      await pumpTransport(
        tester,
        router: _playerRouter(),
        width: 800,
        seedTranscript: true,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalTransportBar)),
      );
      expect(container.read(transcriptBlurModeProvider), isFalse);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(container.read(transcriptBlurModeProvider), isTrue);
    });
  });
}
