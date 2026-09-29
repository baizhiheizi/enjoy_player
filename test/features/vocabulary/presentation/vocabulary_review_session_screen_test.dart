import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_session_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _AuthSignedOutCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/vocabulary/review',
    routes: [
      GoRoute(path: '/vocabulary', builder: (_, _) => const Text('vocabulary')),
      GoRoute(
        path: '/vocabulary/review',
        builder: (_, _) => const VocabularyReviewSessionScreen(),
      ),
    ],
  );
}

Widget _wrap({required ProviderContainer container, required GoRouter router}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late GoRouter router;

  Future<void> seedWords(int count) async {
    final repo = VocabularyRepository(db);
    for (var i = 0; i < count; i++) {
      await repo.addWithContext(
        word: 'word$i',
        language: 'en',
        targetLanguage: 'zh',
        text: 'Context for word$i',
        sourceType: VocabularySourceType.video,
        sourceId: 'v$i',
        mediaLocator: MediaLocator(start: i * 1000, duration: 2000),
        now: DateTime.utc(2020, 1, 1).add(Duration(hours: i)),
      );
    }
  }

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authCtrlProvider.overrideWith(_AuthSignedOutCtrl.new),
      ],
    );
    router = _buildRouter();
  });

  tearDown(() async {
    router.dispose();
    container.dispose();
    await db.close();
  });

  testWidgets('renders the inactive-session branch (no crash)', (tester) async {
    await tester.pumpWidget(_wrap(container: container, router: router));
    await tester.pumpAndSettle();

    expect(
      find.byType(VocabularyReviewSessionScreen).evaluate().isNotEmpty ||
          find.text('vocabulary').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('renders session header + flashcard when session is active', (
    tester,
  ) async {
    await seedWords(2);
    await container
        .read(vocabularyReviewSessionProvider.notifier)
        .start(
          const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
          now: DateTime.utc(2030, 1, 1),
        );

    await tester.pumpWidget(_wrap(container: container, router: router));
    await tester.pumpAndSettle();

    expect(find.byType(VocabularyReviewSessionScreen), findsOneWidget);

    expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
    expect(find.text("Don't Know"), findsNothing);

    await tester.tap(find.text('Tap to flip'));
    await tester.pumpAndSettle();
    expect(find.text("Don't Know"), findsOneWidget);
    expect(find.text('Know'), findsOneWidget);
    expect(find.text('Know Well'), findsOneWidget);
  });

  testWidgets('renders the completed body when session is done', (
    tester,
  ) async {
    await seedWords(1);
    await container
        .read(vocabularyReviewSessionProvider.notifier)
        .start(
          const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
          now: DateTime.utc(2030, 1, 1),
        );
    final session = container.read(vocabularyReviewSessionProvider.notifier);
    session.flip();
    await session.rate(VocabularyRating.know);

    await tester.pumpWidget(_wrap(container: container, router: router));
    await tester.pumpAndSettle();

    expect(find.byIcon(EnjoyIcons.checkCircle), findsOneWidget);
  });

  testWidgets('close icon is tappable without crashing', (tester) async {
    await seedWords(1);
    await container
        .read(vocabularyReviewSessionProvider.notifier)
        .start(
          const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
          now: DateTime.utc(2030, 1, 1),
        );

    await tester.pumpWidget(_wrap(container: container, router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(EnjoyIcons.close));
    await tester.pumpAndSettle();
  });
}
