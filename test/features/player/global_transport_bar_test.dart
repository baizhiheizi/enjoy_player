import 'package:drift/native.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/global_transport_bar.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
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

List<Override> _transportOverrides({
  required FakePlayerEngine fake,
  required AppDatabase db,
}) {
  return [
    appDatabaseProvider.overrideWithValue(db),
    playerEngineTestDoubleProvider.overrideWithValue(fake),
    playerControllerProvider.overrideWith(
      () => _SessionPlayerController(_testSession()),
    ),
    transcriptHasLinesForMediaProvider(
      _kMediaId,
    ).overrideWith((ref) => Stream.value(true)),
    playerIsPlayingProvider.overrideWith((ref) => Stream.value(false)),
    playerIsBufferingProvider.overrideWith((ref) => Stream.value(false)),
    allTranscriptsForMediaProvider(
      _kMediaId,
    ).overrideWith((ref) => Stream.value(const <TranscriptTrack>[])),
    transcriptFetchCtrlProvider(_kMediaId).overrideWithValue(
      const TranscriptFetchUiState(status: TranscriptFetchStatus.idle),
    ),
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
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _transportHarness(
        router: router,
        overrides: _transportOverrides(fake: fake, db: db),
        width: width,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('GlobalTransportBar narrow layout', () {
    for (final width in [320.0, 375.0, 430.0]) {
      testWidgets('player at ${width.toInt()}px shows prev/next, not replay', (
        tester,
      ) async {
        await pumpTransport(tester, router: _playerRouter(), width: width);

        expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
        expect(find.byIcon(Icons.replay_rounded), findsNothing);
      });
    }

    testWidgets('mini at 320px shows prev/next, hides expand', (tester) async {
      await pumpTransport(tester, router: _libraryRouter(), width: 320);

      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);
    });
  });
}
