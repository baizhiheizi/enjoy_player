// Per-command tests for the library.search hotkey command (issue #719): the
// route gate (`librarySearchHotkeyEnabledForPath`) and the focus pulse
// (`requestLibrarySearchFocus` schedules a double frame callback, so these
// are widget tests with a mounted router).
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/library/application/library_search_focus_provider.dart';
import 'package:enjoy_player/features/library/application/library_search_hotkey_command.dart';
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
        path: '/player/:mediaId',
        builder: (_, _) => const Scaffold(body: Text('player')),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const Scaffold(body: Text('sign-in')),
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
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return (router: router, container: container);
}

Future<void> _runCommand(
  WidgetTester tester,
  ProviderContainer container,
) async {
  const LibrarySearchHotkeyCommand().execute(
    HotkeyCtx(read: container.read, listenerContext: null),
  );
  // requestLibrarySearchFocus defers the pulse behind two frame callbacks.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('on /library → pulses the search focus request', (tester) async {
    final h = await _mountHarness(tester);
    expect(h.container.read(librarySearchFocusRequestProvider), 0);
    await _runCommand(tester, h.container);
    expect(h.container.read(librarySearchFocusRequestProvider), greaterThan(0));
  });

  testWidgets('on /player/:id → canExecute false, no pulse', (tester) async {
    final h = await _mountHarness(tester, initialLocation: '/player/x');
    final ctx = HotkeyCtx(read: h.container.read, listenerContext: null);
    expect(const LibrarySearchHotkeyCommand().canExecute(ctx), isFalse);
    await _runCommand(tester, h.container);
    expect(h.container.read(librarySearchFocusRequestProvider), 0);
  });

  testWidgets('on /sign-in → canExecute false, no pulse', (tester) async {
    final h = await _mountHarness(tester, initialLocation: '/sign-in');
    final ctx = HotkeyCtx(read: h.container.read, listenerContext: null);
    expect(const LibrarySearchHotkeyCommand().canExecute(ctx), isFalse);
    await _runCommand(tester, h.container);
    expect(h.container.read(librarySearchFocusRequestProvider), 0);
  });
}
