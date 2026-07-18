import 'dart:async';

import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveEscapeDismissal', () {
    const base = EscapeDismissalContext(
      cheatsheetOpen: false,
      windowFullscreen: false,
      isRecordingActive: false,
      shellHasPopupRoute: false,
      rootHasPopupRoute: false,
      goRouterCanPop: true,
      path: '/player/media-1',
      isDesktop: true,
    );

    test('cheatsheet open closes cheatsheet first', () {
      expect(
        resolveEscapeDismissal(base.copyWith(cheatsheetOpen: true)),
        EscapeDismissalAction.closeCheatsheet,
      );
    });

    test('fullscreen exits before overlays on desktop', () {
      expect(
        resolveEscapeDismissal(base.copyWith(windowFullscreen: true)),
        EscapeDismissalAction.exitFullscreen,
      );
    });

    test('active recording cancels before route navigation', () {
      expect(
        resolveEscapeDismissal(base.copyWith(isRecordingActive: true)),
        EscapeDismissalAction.cancelRecording,
      );
    });

    test('shell popup pops without collapsing player route', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(shellHasPopupRoute: true, goRouterCanPop: true),
        ),
        EscapeDismissalAction.popShellPopup,
      );
    });

    test('root popup pops when shell has none', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(rootHasPopupRoute: true, goRouterCanPop: true),
        ),
        EscapeDismissalAction.popRootPopup,
      );
    });

    test('shell popup wins over root popup', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(
            shellHasPopupRoute: true,
            rootHasPopupRoute: true,
            goRouterCanPop: true,
          ),
        ),
        EscapeDismissalAction.popShellPopup,
      );
    });

    test('idle player route is a no-op', () {
      expect(resolveEscapeDismissal(base), EscapeDismissalAction.noopOnPlayer);
    });

    test('non-player route pops GoRouter when no overlay', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(path: '/library', goRouterCanPop: true),
        ),
        EscapeDismissalAction.popGoRouter,
      );
    });

    test('returns null when nothing applies on non-player route', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(path: '/library', goRouterCanPop: false),
        ),
        isNull,
      );
    });

    test('page canPop alone does not count as overlay', () {
      // Pushed GoRouter pages make Navigator.canPop true; only PopupRoute
      // should trigger popShellPopup / popRootPopup.
      expect(
        resolveEscapeDismissal(
          base.copyWith(path: '/settings', goRouterCanPop: true),
        ),
        EscapeDismissalAction.popGoRouter,
      );
    });
  });

  group('navigatorHasTopPopupRoute', () {
    testWidgets('false when only page routes are on the stack', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('home')),
          routes: {'/next': (_) => const Scaffold(body: Text('next'))},
        ),
      );
      unawaited(navKey.currentState!.pushNamed('/next'));
      await tester.pumpAndSettle();

      expect(navigatorHasTopPopupRoute(navKey.currentState), isFalse);
      expect(navKey.currentState!.canPop(), isTrue);
    });

    testWidgets('true when a dialog PopupRoute is on top', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    unawaited(
                      showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(title: Text('dlg')),
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(navigatorHasTopPopupRoute(navKey.currentState), isTrue);
      expect(find.text('dlg'), findsOneWidget);

      // Inspection must not dismiss the dialog.
      expect(find.text('dlg'), findsOneWidget);
    });

    testWidgets('null navigator is false', (tester) async {
      expect(navigatorHasTopPopupRoute(null), isFalse);
    });
  });
}

extension on EscapeDismissalContext {
  EscapeDismissalContext copyWith({
    bool? cheatsheetOpen,
    bool? windowFullscreen,
    bool? isRecordingActive,
    bool? shellHasPopupRoute,
    bool? rootHasPopupRoute,
    bool? goRouterCanPop,
    String? path,
    bool? isDesktop,
  }) {
    return EscapeDismissalContext(
      cheatsheetOpen: cheatsheetOpen ?? this.cheatsheetOpen,
      windowFullscreen: windowFullscreen ?? this.windowFullscreen,
      isRecordingActive: isRecordingActive ?? this.isRecordingActive,
      shellHasPopupRoute: shellHasPopupRoute ?? this.shellHasPopupRoute,
      rootHasPopupRoute: rootHasPopupRoute ?? this.rootHasPopupRoute,
      goRouterCanPop: goRouterCanPop ?? this.goRouterCanPop,
      path: path ?? this.path,
      isDesktop: isDesktop ?? this.isDesktop,
    );
  }
}
