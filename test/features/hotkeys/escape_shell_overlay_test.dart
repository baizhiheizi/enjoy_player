import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';

/// Mirrors [AppHotkeysKeyboardListener]'s Escape dispatch using the same
/// shell/root [PopupRoute] probe (without mounting the full hotkeys stack).
void _dispatchEscape({
  required GoRouter goRouter,
  required GlobalKey<NavigatorState> shellKey,
  required GlobalKey<NavigatorState> rootKey,
}) {
  final shellNav = shellKey.currentState;
  final rootNav = rootKey.currentState;
  final action = resolveEscapeDismissal(
    EscapeDismissalContext(
      cheatsheetOpen: false,
      windowFullscreen: false,
      isRecordingActive: false,
      shellHasPopupRoute: navigatorHasTopPopupRoute(shellNav),
      rootHasPopupRoute: navigatorHasTopPopupRoute(rootNav),
      goRouterCanPop: goRouter.canPop(),
      path: goRouter.state.uri.path,
      isDesktop: true,
    ),
  );
  switch (action) {
    case EscapeDismissalAction.popShellPopup:
      if (shellNav != null) unawaited(shellNav.maybePop());
      return;
    case EscapeDismissalAction.popRootPopup:
      if (rootNav != null) unawaited(rootNav.maybePop());
      return;
    case EscapeDismissalAction.popGoRouter:
      goRouter.pop();
      return;
    case EscapeDismissalAction.closeCheatsheet:
    case EscapeDismissalAction.exitFullscreen:
    case EscapeDismissalAction.cancelRecording:
    case EscapeDismissalAction.noopOnPlayer:
    case null:
      return;
  }
}

void main() {
  testWidgets('Escape dismisses shell sheet before popping the pushed page', (
    tester,
  ) async {
    final rootKey = GlobalKey<NavigatorState>(debugLabel: 'test-root');
    final shellKey = GlobalKey<NavigatorState>(debugLabel: 'test-shell');

    final goRouter = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/home',
      routes: [
        ShellRoute(
          navigatorKey: shellKey,
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Text('home'),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                return Scaffold(
                  body: Column(
                    children: [
                      const Text('settings'),
                      Builder(
                        builder: (context) {
                          return TextButton(
                            onPressed: () {
                              unawaited(
                                showModalBottomSheet<void>(
                                  context: context,
                                  builder: (sheetContext) {
                                    return const SizedBox(
                                      height: 120,
                                      child: Center(child: Text('sheet-body')),
                                    );
                                  },
                                ),
                              );
                            },
                            child: const Text('open-sheet'),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));
    await tester.pumpAndSettle();

    unawaited(goRouter.push('/settings'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
    expect(goRouter.state.uri.path, '/settings');

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
    expect(find.text('sheet-body'), findsOneWidget);

    _dispatchEscape(goRouter: goRouter, shellKey: shellKey, rootKey: rootKey);
    await tester.pumpAndSettle();

    expect(find.text('sheet-body'), findsNothing);
    expect(find.text('settings'), findsOneWidget);
    expect(goRouter.state.uri.path, '/settings');

    _dispatchEscape(goRouter: goRouter, shellKey: shellKey, rootKey: rootKey);
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(goRouter.state.uri.path, '/home');
  });
}
