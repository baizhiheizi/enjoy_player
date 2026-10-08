import 'package:drift/native.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/nav_item_pill.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/sidebar_account_chip.dart';
import 'package:enjoy_player/features/player/presentation/widgets/app_sidebar.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import '../../../../helpers/chrome_icon_finders.dart';
import 'package:go_router/go_router.dart';

Widget buildHost(ProviderContainer container, GoRouter router) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      locale: const Locale('en', 'US'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 't@example.com', name: 'An Lee'),
  );
}

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: AppSidebar()),
    ),
    GoRoute(
      path: '/discover',
      builder: (_, _) => const Scaffold(body: AppSidebar()),
    ),
    GoRoute(
      path: '/library',
      builder: (_, _) => const Scaffold(body: AppSidebar()),
    ),
    GoRoute(
      path: '/vocabulary',
      builder: (_, _) => const Scaffold(body: AppSidebar()),
    ),
    GoRoute(
      path: '/craft',
      builder: (_, _) => const Scaffold(body: AppSidebar()),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const Scaffold(body: AppSidebar()),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    router = _router('/');
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        deviceGlobalAppDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    container.dispose();
    await db.close();
  });

  Future<List<NavItemPill>> pumpAndFindPills(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(buildHost(container, router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return tester.widgetList<NavItemPill>(find.byType(NavItemPill)).toList();
  }

  testWidgets('AppSidebar renders brand row, search field and nav pills', (
    tester,
  ) async {
    await pumpAndFindPills(tester);

    expect(findChromeIcon(EnjoyChromeGlyph.home), findsOneWidget);
    expect(findChromeIcon(EnjoyChromeGlyph.compass), findsOneWidget);
    expect(findChromeIcon(EnjoyChromeGlyph.library), findsOneWidget);
    expect(findChromeIcon(EnjoyChromeGlyph.gear), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.vocabularyTitle), findsOneWidget);
    expect(find.text(l10n.craftScreenTitle), findsOneWidget);
    expect(find.byType(EnjoyKeycap), findsNWidgets(2));
  });

  testWidgets('AppSidebar tapping the Discover nav pill navigates', (
    tester,
  ) async {
    await pumpAndFindPills(tester);

    await tester.tap(findChromeIcon(EnjoyChromeGlyph.compass));
    await tester.pump();

    expect(router.state.uri.path, '/discover');
  });

  testWidgets('AppSidebar search field calls setQuery on change', (
    tester,
  ) async {
    await pumpAndFindPills(tester);

    await tester.enterText(find.byType(TextField).first, 'foo');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, 'foo');
  });

  testWidgets('AppSidebar shows the due badge when vocabulary has due items', (
    tester,
  ) async {
    final dueContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        deviceGlobalAppDatabaseProvider.overrideWithValue(db),
        vocabularyStatsProvider.overrideWithValue(
          const VocabularyStats(
            total: 120,
            due: 14,
            newCount: 10,
            learningCount: 40,
            reviewingCount: 50,
            masteredCount: 20,
          ),
        ),
      ],
    );
    addTearDown(dueContainer.dispose);
    final saved = container;
    container = dueContainer;
    addTearDown(() => container = saved);
    await pumpAndFindPills(tester);

    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('AppSidebar maps routes to the selected row', (tester) async {
    final cases = {
      '/vocabulary': 'Vocabulary',
      '/craft': 'Craft',
      '/settings': 'Settings',
    };
    for (final entry in cases.entries) {
      final routeRouter = _router(entry.key);
      addTearDown(routeRouter.dispose);
      final savedRouter = router;
      router = routeRouter;
      final pills = await pumpAndFindPills(tester);
      final selected = pills.where((p) => p.selected).toList();
      expect(selected, hasLength(1), reason: 'route ${entry.key}');
      expect(selected.single.label, entry.value, reason: 'route ${entry.key}');
      router = savedRouter;
    }
  });

  testWidgets('AppSidebar drops the continue practicing card', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpAndFindPills(tester);

    expect(find.text(l10n.homeContinuePracticing), findsNothing);
  });

  testWidgets('AppSidebar shows the sync line when signed in', (tester) async {
    final authedContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        deviceGlobalAppDatabaseProvider.overrideWithValue(db),
        authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
        syncQueueSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            const SyncQueueSnapshot(
              retryablePending: 0,
              permanentlyFailed: 0,
              detailRows: [],
            ),
          ),
        ),
      ],
    );
    addTearDown(authedContainer.dispose);
    final saved = container;
    container = authedContainer;
    addTearDown(() => container = saved);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpAndFindPills(tester);

    expect(find.text(l10n.syncSettingsTileSubtitleUpToDate), findsOneWidget);
    expect(find.byType(SidebarAccountChip), findsOneWidget);
  });
}
