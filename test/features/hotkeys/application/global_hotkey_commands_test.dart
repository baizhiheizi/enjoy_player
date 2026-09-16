// Per-command tests for the global-navigation hotkey commands (issue #719):
// settings / craft navigation through a mounted GoRouter, the stub search
// notice, and global.help's unmounted-router gate. The cheatsheet open/close
// arms (dialog + cheatsheet state) stay covered end-to-end in
// `test/features/hotkeys/app_hotkeys_keyboard_listener_test.dart`.
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/features/hotkeys/application/global_hotkey_commands.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<({GoRouter router, ProviderContainer container})> _mountHarness(
  WidgetTester tester, {
  String initialLocation = '/library',
}) async {
  late GoRouter router;
  router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/library',
        builder: (_, _) => const Scaffold(body: Text('library')),
      ),
      GoRoute(
        path: '/craft',
        builder: (_, _) => const Scaffold(body: Text('craft')),
      ),
      GoRoute(
        path: '/craft/history',
        builder: (_, _) => const Scaffold(body: Text('craft-history')),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('settings')),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [appRouterProvider.overrideWithValue(router)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return (router: router, container: container);
}

void main() {
  test('registry keeps the old global block order', () {
    expect(globalHotkeyCommands.map((c) => c.actionId).toList(), [
      'global.help',
      'global.settings',
      'global.craft',
      'global.search',
    ]);
  });

  group('global.help', () {
    test('canExecute is false before the router navigator is mounted', () {
      final container = ProviderContainer(
        overrides: [
          // A headless GoRouter: its navigator key has no context until a
          // Router widget mounts, which is exactly the gate under test.
          appRouterProvider.overrideWithValue(
            GoRouter(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (_, _) => const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final ctx = HotkeyCtx(read: container.read, listenerContext: null);
      expect(const GlobalHelpHotkeyCommand().canExecute(ctx), isFalse);
    });
  });

  group('global.settings', () {
    testWidgets('navigates to /settings', (tester) async {
      final h = await _mountHarness(tester);
      const GlobalSettingsHotkeyCommand().execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/settings');
    });
  });

  group('global.craft', () {
    testWidgets('navigates to /craft from library', (tester) async {
      final h = await _mountHarness(tester);
      expect(h.router.state.uri.path, '/library');
      const GlobalCraftHotkeyCommand().execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/craft');
    });

    testWidgets('consumed but no-ops when already on /craft', (tester) async {
      final h = await _mountHarness(tester, initialLocation: '/craft');
      const command = GlobalCraftHotkeyCommand();
      expect(command.canExecute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      ), isTrue);
      command.execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/craft');
    });

    testWidgets('consumed but no-ops on a /craft sub-route', (tester) async {
      final h = await _mountHarness(tester, initialLocation: '/craft/history');
      const GlobalCraftHotkeyCommand().execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      await tester.pumpAndSettle();
      expect(h.router.state.uri.path, '/craft/history');
    });
  });

  group('global.search', () {
    testWidgets('shows the AppNotice stub without throwing', (tester) async {
      final h = await _mountHarness(tester);
      const GlobalSearchHotkeyCommand().execute(
        HotkeyCtx(read: h.container.read, listenerContext: null),
      );
      await tester.pumpAndSettle();
      // AppNotice surfaces through the global scaffold messenger key.
      expect(appScaffoldMessengerKey.currentState, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}
