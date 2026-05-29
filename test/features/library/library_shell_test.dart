import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/presentation/library_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

Widget _themedRouter({
  required GoRouter router,
  List<Override> overrides = const [],
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
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
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('library shell routing', () {
    testWidgets('/cloud redirects to library cloud source', (tester) async {
      final router = GoRouter(
        initialLocation: '/cloud',
        redirect: (_, state) {
          final loc = state.matchedLocation;
          if (loc == '/cloud' || loc.startsWith('/cloud/')) {
            return libraryRouteForSource(LibrarySource.cloud);
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/library',
            builder: (_, state) {
              final source = librarySourceFromUri(state.uri);
              return Scaffold(body: Text('library-${source.name}'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(_themedRouter(router: router));
      await tester.pumpAndSettle();

      expect(find.text('library-cloud'), findsOneWidget);
      expect(router.state.uri.path, '/library');
      expect(router.state.uri.queryParameters['source'], 'cloud');
    });
  });

  group('LibraryScreen shell chrome', () {
    testWidgets('cloud source shows refresh and hides search', (tester) async {
      final router = GoRouter(
        initialLocation: '/library?source=cloud',
        routes: [
          GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _themedRouter(
          router: router,
          overrides: [
            authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
            libraryFilteredListsProvider.overrideWith(
              (ref) => Stream.value((audio: <Media>[], video: <Media>[])),
            ),
            libraryMediaProvider.overrideWith((ref) => Stream.value(<Media>[])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh this tab'), findsOneWidget);
      expect(find.byTooltip('Switch to local'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Local'), findsNothing);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    });

    testWidgets(
      'local source shows import and compact search on narrow width',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(
          initialLocation: '/library',
          routes: [
            GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          _themedRouter(
            router: router,
            overrides: [
              authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
              libraryFilteredListsProvider.overrideWith(
                (ref) => Stream.value((audio: <Media>[], video: <Media>[])),
              ),
              libraryMediaProvider.overrideWith(
                (ref) => Stream.value(<Media>[]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Import'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets('source toggle navigates to cloud query', (tester) async {
      final router = GoRouter(
        initialLocation: '/library',
        routes: [
          GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _themedRouter(
          router: router,
          overrides: [
            authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
            libraryFilteredListsProvider.overrideWith(
              (ref) => Stream.value((audio: <Media>[], video: <Media>[])),
            ),
            libraryMediaProvider.overrideWith((ref) => Stream.value(<Media>[])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Switch to cloud'));
      await tester.pumpAndSettle();

      expect(router.state.uri.queryParameters['source'], 'cloud');
      expect(find.byTooltip('Refresh this tab'), findsOneWidget);
    });
  });
}
