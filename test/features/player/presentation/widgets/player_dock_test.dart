import 'package:drift/native.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/fake_player_engine.dart';

class _SessionController extends PlayerController {
  @override
  PlaybackSession? build() {
    final now = DateTime(2026, 1, 1);
    return PlaybackSession(
      mediaId: 'm1',
      dexieTargetType: 'Audio',
      mediaType: 'audio',
      mediaTitle: 'Dock test item',
      durationSeconds: 349,
      currentTimeSeconds: 78,
      currentSegmentIndex: 3,
      language: 'en',
      startedAt: now,
      lastActiveAt: now,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakePlayerEngine engine;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    engine = FakePlayerEngine();
  });

  tearDown(() async {
    await db.close();
    await engine.dispose();
  });

  Future<ProviderContainer> pumpDock(
    WidgetTester tester, {
    bool echoActive = false,
    bool recording = false,
    bool hideText = false,
  }) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        deviceGlobalAppDatabaseProvider.overrideWithValue(db),
        playerEngineTestDoubleProvider.overrideWithValue(engine),
        playerControllerProvider.overrideWith(_SessionController.new),
        transcriptLinesForMediaProvider('m1').overrideWith(
          (ref) => Stream.value(const [
            TranscriptLine(text: 'one', startMs: 0, durationMs: 4000),
            TranscriptLine(text: 'two', startMs: 4000, durationMs: 4000),
            TranscriptLine(text: 'three', startMs: 8000, durationMs: 4000),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (echoActive) {
      container
          .read(echoModeProvider.notifier)
          .activate(
            startLineIndex: 0,
            endLineIndex: 1,
            startTimeSeconds: 0,
            endTimeSeconds: 8,
          );
    }
    if (hideText) {
      container.read(transcriptBlurModeProvider.notifier).activate();
    }
    if (recording) {
      container.read(shadowReadingHotkeyBusProvider.notifier)
        ..setRecordingActive(true)
        ..pulseRecording();
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final chrome = playbackChromeOf(
              ref.watch(playerControllerProvider),
            );
            return MaterialApp.router(
              theme: ThemeData(
                colorScheme: scheme,
                useMaterial3: true,
                extensions: [EnjoyThemeTokens.build(scheme)],
              ),
              locale: const Locale('en', 'US'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: GoRouter(
                initialLocation: '/player/m1',
                routes: [
                  GoRoute(
                    path: '/player/:id',
                    builder: (_, _) => Scaffold(
                      body: const SizedBox.shrink(),
                      bottomNavigationBar: chrome == null
                          ? null
                          : PlayerDock(chrome: chrome),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  testWidgets('Listen dock shows speed and the play ring, no Hide pill', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);

    expect(find.text(l10n.playerDockHideText), findsNothing);
    expect(find.byIcon(EnjoyIcons.play), findsOneWidget);
    expect(find.text('1.0×'), findsOneWidget);
    expect(find.text(l10n.playerDockRecord), findsNothing);
    expect(find.byType(TransportVolumeButton), findsOneWidget);
  });

  testWidgets('Listen dock fits at 400 width (phone layout)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone Listen dock starts with Replay (R3)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);

    final replay = find.byIcon(EnjoyIcons.replay);
    expect(replay, findsOneWidget);
    expect(
      tester.getCenter(replay).dx,
      lessThan(tester.getCenter(find.byIcon(EnjoyIcons.skipBack)).dx),
    );
  });

  testWidgets('Echo dock swaps in Play/Pause and Record', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, echoActive: true);

    expect(find.text(l10n.play), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.micFill), findsNothing);
    expect(find.text(l10n.playerDockLoopingLines(1, 2)), findsOneWidget);
    expect(find.textContaining('+ adds a line, − drops one'), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.skipBack), findsOneWidget);
  });

  testWidgets('Echo dock play/pause pill toggles playback', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, echoActive: true);

    await tester.tap(find.byIcon(EnjoyIcons.play));
    await tester.pump();
    expect(engine.playOrPauseCallCount, 1);

    expect(find.text(l10n.pause), findsNothing);
  });

  testWidgets('Echo dock labels Play and Record on phone', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, echoActive: true);

    expect(find.text(l10n.play), findsOneWidget);
    expect(find.text(l10n.playerDockRecord), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recording dock shows Cancel and Stop', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, recording: true);

    expect(find.text(l10n.asrLongMediaConfirmCancel), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.shadowRecordingStop), findsOneWidget);
    expect(find.text(l10n.playerDockRecord), findsNothing);
  });

  testWidgets('dock sits on paper with the progress strip mounted', (
    tester,
  ) async {
    await pumpDock(tester);
    final t = EnjoyThemeTokens.build(
      ColorScheme.fromSeed(seedColor: Colors.blue),
    );

    expect(find.byType(SentenceRuler), findsOneWidget);
    final dockContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byType(SentenceRuler),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((dockContainer.decoration! as BoxDecoration).color, t.paper);
  });

  testWidgets('desktop Listen dock ends the transport with Repeat (R1)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = await pumpDock(tester);

    final repeat = find.byKey(const ValueKey('dock-repeat'));
    expect(repeat, findsOneWidget);
    expect(
      tester.getCenter(repeat).dx,
      greaterThan(tester.getCenter(find.byIcon(EnjoyIcons.skipForward)).dx),
    );
    expect(
      container.read(playerPreferencesCtrlProvider).repeatMode,
      RepeatMode.none,
    );

    await tester.tap(repeat);
    await tester.pump();
    expect(
      container.read(playerPreferencesCtrlProvider).repeatMode,
      RepeatMode.single,
    );

    await tester.tap(repeat);
    await tester.pump();
    expect(
      container.read(playerPreferencesCtrlProvider).repeatMode,
      RepeatMode.segment,
    );

    await tester.tap(repeat);
    await tester.pump();
    expect(
      container.read(playerPreferencesCtrlProvider).repeatMode,
      RepeatMode.none,
    );
  });

  testWidgets('phone Listen dock has no Repeat (speed alone on the right)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);

    expect(find.byKey(const ValueKey('dock-repeat')), findsNothing);
    expect(find.byKey(const ValueKey('dock-speed')), findsOneWidget);
  });

  testWidgets('speed is a 54px mono button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);

    expect(tester.getSize(find.byKey(const ValueKey('dock-speed'))).width, 54);
    expect(find.text('1.0×'), findsOneWidget);
  });

  testWidgets('recording readout counts the take against the loop length', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, echoActive: true, recording: true);

    expect(find.textContaining('Recording ·'), findsOneWidget);
    expect(find.textContaining('of 8.0s'), findsOneWidget);
  });

  testWidgets('Dictate readout says which line is being dictated', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, hideText: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('Dictating line'), findsOneWidget);
  });

  testWidgets('Listen readout shows the line and how many are practised', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('of 3'), findsOneWidget);
    expect(find.text('No lines practised yet'), findsOneWidget);
  });
}
