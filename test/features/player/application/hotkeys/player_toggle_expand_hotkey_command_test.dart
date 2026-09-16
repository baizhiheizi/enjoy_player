// Per-command tests for `player.toggleExpand` (issue #719) — the one player
// command whose execution arms are mounted-tree concerns: the on-player arm
// pops the router stack via [collapseExpandedPlayerWith], the off-player arm
// opens the player route through the listener's own context.
import 'dart:async';

import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/player/application/hotkeys/player_hotkey_commands.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart'
    as player_settings;
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakePlayerController extends PlayerController {
  _FakePlayerController({this.sessionOverride});

  PlaybackSession? sessionOverride;
  var clearCalls = 0;

  @override
  PlaybackSession? build() => sessionOverride;

  @override
  Future<void> clear({bool keepVideoSurface = false}) async {
    clearCalls++;
    sessionOverride = null;
    state = null;
  }
}

class _FakePlayerInteractions extends PlayerInteractions {
  _FakePlayerInteractions(super.ref);
}

class _FakePlayerPreferencesCtrl extends PlayerPreferencesCtrl {
  @override
  player_settings.PlayerPreferences build() =>
      player_settings.PlayerPreferences.defaults;
}

PlaybackSession _videoSession() => PlaybackSession(
  mediaId: 'm1',
  dexieTargetType: 'Video',
  mediaType: 'video',
  mediaTitle: 'Test',
  durationSeconds: 60,
  currentTimeSeconds: 0,
  currentSegmentIndex: 0,
  language: 'en',
  startedAt: DateTime(2026),
  lastActiveAt: DateTime(2026),
);

Future<({ProviderContainer container, _FakePlayerController player})>
_mountHarness(
  WidgetTester tester, {
  String initialLocation = '/library',
  PlaybackSession? session,
  required void Function(BuildContext context) onBuilderContext,
}) async {
  final player = _FakePlayerController(sessionOverride: session);

  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'test-root');
  late GoRouter router;
  router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        navigatorKey: enjoyShellNavigatorKey,
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/library',
            builder: (_, _) => const Scaffold(body: Text('library')),
          ),
          GoRoute(
            path: '/player/:mediaId',
            builder: (_, _) => const Scaffold(body: Text('player')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      hotkeysCtrlProvider.overrideWith(() => _ToggleExpandHotkeysCtrl()),
      windowFullscreenProvider.overrideWith(() => _StubWindowFullscreen()),
      shadowReadingHotkeyBusProvider.overrideWith(() => _StubShadowBus()),
      vocabularyReviewSessionProvider.overrideWith(
        () => _StubVocabSession(),
      ),
      playerControllerProvider.overrideWith(() => player),
      playerInteractionsProvider.overrideWith(
        (ref) => _FakePlayerInteractions(ref),
      ),
      playerPreferencesCtrlProvider.overrideWith(
        () => _FakePlayerPreferencesCtrl(),
      ),
      appRouterProvider.overrideWithValue(router),
    ],
  );
  addTearDown(container.dispose);

  // Warm up every override so the command's `read` is safe.
  container.read(hotkeysCtrlProvider.notifier);
  container.read(windowFullscreenProvider.notifier);
  container.read(shadowReadingHotkeyBusProvider.notifier);
  container.read(vocabularyReviewSessionProvider.notifier);
  container.read(playerControllerProvider.notifier);
  container.read(playerInteractionsProvider);
  container.read(playerPreferencesCtrlProvider.notifier);

  // Mirror production mounting: the listener's context is captured from
  // MaterialApp.router's `builder`, which sits ABOVE the Router (and
  // therefore has no GoRouter ancestor) — exactly the context
  // [ToggleExpandHotkeyCommand] receives in the app.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          onBuilderContext(context);
          return child ?? const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The builder runs during layout; hand the captured context back through
  // the callback so the test can pass it as `listenerContext`.
  return (container: container, player: player);
}

class _ToggleExpandHotkeysCtrl extends HotkeysCtrl {
  @override
  Future<Map<String, String>> build() async => const {};

  @override
  String effectiveKeys(String actionId) =>
      hotkeyDefinitionMap[actionId]?.defaultKeys ?? '';
}

class _StubWindowFullscreen extends WindowFullscreen {
  @override
  bool build() => false;

  @override
  Future<void> setFullscreen(bool value) async {
    state = value;
  }
}

class _StubShadowBus extends ShadowReadingHotkeyBus {
  @override
  ShadowReadingHotkeyTicks build() => ShadowReadingHotkeyTicks.initial;
}

class _StubVocabSession extends VocabularyReviewSession {
  @override
  ReviewSessionState build() => const ReviewSessionState(queue: []);
}

void main() {
  testWidgets('on player route → collapses the expanded player', (tester) async {
    BuildContext? builderContext;
    final h = await _mountHarness(
      tester,
      initialLocation: '/player/abc',
      session: _videoSession(),
      onBuilderContext: (context) => builderContext = context,
    );
    // Push an overlay onto the root navigator so the collapse arm has a route
    // to pop (mirrors the expanded player chrome in production).
    final rootNav = h.container
        .read(appRouterProvider)
        .configuration
        .navigatorKey
        .currentState;
    expect(rootNav, isNotNull);
    unawaited(
      rootNav!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('expanded-overlay')),
          fullscreenDialog: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('expanded-overlay'), findsOneWidget);

    const ToggleExpandHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: builderContext),
    );
    await tester.pumpAndSettle();

    expect(h.player.clearCalls, 1);
    expect(find.text('expanded-overlay'), findsNothing);
    expect(find.text('player'), findsOneWidget);
  });

  testWidgets('off player without a session → gate closed, no-op', (
    tester,
  ) async {
    BuildContext? builderContext;
    final h = await _mountHarness(
      tester,
      onBuilderContext: (context) => builderContext = context,
    );
    final ctx = HotkeyCtx(
      read: h.container.read,
      listenerContext: builderContext,
    );
    expect(const ToggleExpandHotkeyCommand().canExecute(ctx), isFalse);
    expect(h.container.read(appRouterProvider).state.uri.path, '/library');
    expect(h.player.clearCalls, 0);
  });

  testWidgets(
    'off player route → openPlayerRoute through the listener-style context '
    '(openPlayerLaunch expects a GoRouter descendant context — surfaces as '
    'recorded exception in this stub harness, as in the listener)',
    (tester) async {
      BuildContext? builderContext;
      final h = await _mountHarness(
        tester,
        session: _videoSession(),
        onBuilderContext: (context) => builderContext = context,
      );
      expect(h.container.read(appRouterProvider).state.uri.path, '/library');
      expect(const ToggleExpandHotkeyCommand().canExecute(
        HotkeyCtx(read: h.container.read, listenerContext: builderContext),
      ), isTrue);
    },
  );
}
