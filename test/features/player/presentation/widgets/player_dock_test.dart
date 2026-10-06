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
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<void> pumpDock(
    WidgetTester tester, {
    bool echoActive = false,
    bool recording = false,
  }) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        deviceGlobalAppDatabaseProvider.overrideWithValue(db),
        playerEngineTestDoubleProvider.overrideWithValue(engine),
        playerControllerProvider.overrideWith(_SessionController.new),
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
  }

  testWidgets('Listen dock shows hide text, speed, and the play ring', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);

    expect(find.text(l10n.playerDockHideText), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.play), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);
    expect(find.text(l10n.playerDockOriginal), findsNothing);
    expect(find.byType(TransportVolumeButton), findsOneWidget);
  });

  testWidgets('Listen dock fits at 400 width (phone layout)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Echo dock swaps in Original and Record', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, echoActive: true);

    expect(find.text(l10n.playerDockOriginal), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.micFill), findsNothing);
    expect(find.textContaining('Lines 1–2'), findsOneWidget);
    expect(find.textContaining(l10n.playerDockLooping), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.skipBack), findsOneWidget);
  });

  testWidgets('Recording dock shows Cancel and Stop', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpDock(tester, recording: true);

    expect(find.text(l10n.asrLongMediaConfirmCancel), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.shadowRecordingStop), findsOneWidget);
    expect(find.text(l10n.playerDockOriginal), findsNothing);
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
}
