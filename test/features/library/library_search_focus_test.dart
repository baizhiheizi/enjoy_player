import 'package:enjoy_player/features/library/application/library_search_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('librarySearchHotkeyEnabledForPath', () {
    test('enabled on shell browse routes', () {
      expect(librarySearchHotkeyEnabledForPath('/'), isTrue);
      expect(librarySearchHotkeyEnabledForPath('/library'), isTrue);
      expect(librarySearchHotkeyEnabledForPath('/library?source=cloud'), isTrue);
      expect(librarySearchHotkeyEnabledForPath('/cloud'), isTrue);
      expect(librarySearchHotkeyEnabledForPath('/settings'), isTrue);
      expect(
        librarySearchHotkeyEnabledForPath('/settings/keyboard'),
        isTrue,
      );
      expect(librarySearchHotkeyEnabledForPath('/profile'), isTrue);
    });

    test('disabled on player and auth-only routes', () {
      expect(librarySearchHotkeyEnabledForPath('/player/abc'), isFalse);
      expect(librarySearchHotkeyEnabledForPath('/sign-in'), isFalse);
      expect(
        librarySearchHotkeyEnabledForPath('/sign-in?from=profile'),
        isFalse,
      );
      expect(librarySearchHotkeyEnabledForPath('/youtube/login'), isFalse);
    });
  });

  group('ensureLibraryRouteForSearch', () {
    testWidgets('navigates to local library from cloud source', (tester) async {
      final router = GoRouter(
        initialLocation: '/library?source=cloud',
        routes: [
          GoRoute(path: '/library', builder: (_, _) => const SizedBox()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      ensureLibraryRouteForSearch(router);

      expect(router.state.uri.path, '/library');
      expect(router.state.uri.queryParameters['source'], isNull);
    });
  });
}
