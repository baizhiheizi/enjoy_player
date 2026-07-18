import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// Mirrors [AppHotkeysKeyboardListener] Escape → [popGoRouter] only.
void _dispatchGlobalEscape(GoRouter goRouter) {
  final action = resolveEscapeDismissal(
    EscapeDismissalContext(
      cheatsheetOpen: false,
      windowFullscreen: false,
      isRecordingActive: false,
      shellHasPopupRoute: false,
      rootHasPopupRoute: false,
      goRouterCanPop: goRouter.canPop(),
      path: goRouter.state.uri.path,
      isDesktop: true,
    ),
  );
  if (action == EscapeDismissalAction.popGoRouter) {
    goRouter.pop();
  }
}

void main() {
  testWidgets('Escape from review pops once to vocabulary (not profile)', (
    tester,
  ) async {
    final shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
    late final GoRouter router;

    // Review Focus handles study shortcuts only — not Escape (global modal.close).
    router = GoRouter(
      initialLocation: '/profile',
      routes: [
        ShellRoute(
          navigatorKey: shellKey,
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const Text('profile')),
            GoRoute(
              path: '/vocabulary',
              builder: (_, _) => const Text('vocabulary'),
            ),
            GoRoute(
              path: '/vocabulary/review',
              builder: (_, _) => Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  // Intentionally ignore Escape — same as production session.
                  if (event.logicalKey == LogicalKeyboardKey.space) {
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: const Text('review'),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    unawaited(router.push('/vocabulary'));
    await tester.pumpAndSettle();
    unawaited(router.push('/vocabulary/review'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/vocabulary/review');

    // Global hotkey path (HardwareKeyboard) — single pop.
    _dispatchGlobalEscape(router);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vocabulary');
    expect(find.text('vocabulary'), findsOneWidget);
    expect(find.text('profile'), findsNothing);

    // Focus must not also pop when Escape is delivered to the focus tree.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/vocabulary');
  });

  testWidgets('leaving /vocabulary/review via onExit clears the session', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final item = VocabularyItem(
      id: 'i1',
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      status: VocabularyStatus.new_,
      easeFactor: 2.5,
      interval: 0,
      nextReviewAt: DateTime.utc(2030),
      reviewsCount: 0,
      contextsCount: 0,
      createdAt: DateTime.utc(2020),
      updatedAt: DateTime.utc(2020),
    );
    container.read(vocabularyReviewSessionProvider.notifier).startWithQueue([
      item,
    ]);

    final shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
    final router = GoRouter(
      initialLocation: '/vocabulary',
      routes: [
        ShellRoute(
          navigatorKey: shellKey,
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/vocabulary',
              builder: (_, _) => const Text('vocabulary'),
            ),
            GoRoute(
              path: '/vocabulary/review',
              onExit: (context, state) {
                final session = container.read(
                  vocabularyReviewSessionProvider.notifier,
                );
                if (session.hasActiveSession) {
                  session.clear();
                }
                return true;
              },
              builder: (_, _) => const Text('review'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(router.push('/vocabulary/review'));
    await tester.pumpAndSettle();
    expect(find.text('review'), findsOneWidget);
    expect(
      container.read(vocabularyReviewSessionProvider).hasActiveSession,
      isTrue,
    );

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('vocabulary'), findsOneWidget);
    expect(
      container.read(vocabularyReviewSessionProvider).hasActiveSession,
      isFalse,
    );
  });
}
