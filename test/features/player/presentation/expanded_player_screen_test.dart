import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/player/application/open_media_provider.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';
import 'package:enjoy_player/features/player/presentation/expanded_player_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_player_engine.dart';

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 't@example.com', name: 'Test'),
  );
}

Widget _wrap({required ProviderContainer container, required Widget child}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: const MediaQueryData(disableAnimations: true, size: Size(800, 600)),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

void main() {
  late AppDatabase db;
  late FakePlayerEngine fake;

  setUpAll(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    fake = FakePlayerEngine();
  });

  tearDownAll(() async {
    await db.close();
    await fake.dispose();
  });

  group('ExpandedPlayerScreen', () {
    testWidgets(
      'renders the loading body when the launch future is still pending',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            playerEngineTestDoubleProvider.overrideWithValue(fake),
            openMediaLaunchProvider.overrideWith((ref, request) async {
              await Completer<void>().future;
            }),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrap(
            container: container,
            child: const ExpandedPlayerScreen(
              launch: PlayerLaunchRequest(mediaId: 'm1'),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SkeletonAppBootstrap), findsOneWidget);
      },
    );

    testWidgets(
      'passes the launch request mediaId through to the loading body',
      (tester) async {
        const customLaunch = PlayerLaunchRequest(
          mediaId: 'custom-media-id',
          autoplay: true,
        );

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            playerEngineTestDoubleProvider.overrideWithValue(fake),
            openMediaLaunchProvider.overrideWith((ref, request) async {
              expect(request.mediaId, 'custom-media-id');
              await Completer<void>().future;
            }),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrap(
            container: container,
            child: const ExpandedPlayerScreen(launch: customLaunch),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(SkeletonAppBootstrap), findsOneWidget);
      },
    );

    testWidgets('shows the YouTube coming-soon body when open fails with the '
        'ADR-0048 Linux opt-out exception', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          openMediaLaunchProvider.overrideWith((ref, request) async {
            throw const YouTubePlaybackUnavailableException(
              'YouTube is not yet available on Linux — coming soon',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(
          container: container,
          child: const ExpandedPlayerScreen(
            launch: PlayerLaunchRequest(mediaId: 'yt1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('YouTube is not yet available on Linux — coming soon.'),
        findsOneWidget,
      );

      const backoffMs = [
        200,
        400,
        800,
        1600,
        3200,
        6400,
        6400,
        6400,
        6400,
        6400,
      ];
      for (final ms in backoffMs) {
        await tester.pump(Duration(milliseconds: ms));
      }
    });
  });
}
