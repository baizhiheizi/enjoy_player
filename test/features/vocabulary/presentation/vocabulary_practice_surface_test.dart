import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_surface_target.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_practice_clip_body.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_practice_echo_body.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _SessionStub extends VocabularyReviewSession {
  _SessionStub(this._initial);

  final ReviewSessionState _initial;

  @override
  ReviewSessionState build() => _initial;
}

ReviewSessionState _baseState({
  ReviewPracticePhase phase = ReviewPracticePhase.none,
}) {
  final item = VocabularyItem(
    id: 'i1',
    word: 'hello',
    language: 'en',
    targetLanguage: 'zh',
    status: VocabularyStatus.new_,
    easeFactor: 2.5,
    interval: 0,
    reviewsCount: 0,
    nextReviewAt: DateTime.utc(2030),
    createdAt: DateTime.utc(2020),
    updatedAt: DateTime.utc(2020),
    contextsCount: 1,
  );
  final ctx = VocabularyContext(
    id: 'c1',
    vocabularyItemId: 'i1',
    text: 'Hello world.',
    sourceType: VocabularySourceType.video,
    sourceId: 'media-1',
    locator: const MediaLocator(start: 1500, duration: 2500),
    createdAt: DateTime.utc(2020),
    updatedAt: DateTime.utc(2020),
  );
  return ReviewSessionState(
    queue: [item],
    contextsByItemId: {
      'i1': [ctx],
    },
    activeContextIndexByItemId: const {'i1': 0},
    practicePhase: phase,
  );
}

Widget _wrap(Widget child, {required List<Override> overrides}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('clipReady claims vocabulary portal target', (tester) async {
    final stub = _SessionStub(_baseState(phase: ReviewPracticePhase.clipReady));
    await tester.pumpWidget(
      _wrap(
        const VocabularyPracticeClipBody(startSec: 1.5, endSec: 4.0),
        overrides: [vocabularyReviewSessionProvider.overrideWith(() => stub)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VocabularyPracticeClipBody)),
    );
    expect(
      container.read(playerSurfaceRegistryProvider)?.id,
      PlayerSurfaceIds.vocabularyClip,
    );
    expect(find.byType(PlayerSurfaceTarget), findsOneWidget);
  });

  testWidgets('clipOpening does not claim portal target', (tester) async {
    final stub = _SessionStub(
      _baseState(phase: ReviewPracticePhase.clipOpening),
    );
    await tester.pumpWidget(
      _wrap(
        const VocabularyPracticeClipBody(startSec: 1.5, endSec: 4.0),
        overrides: [vocabularyReviewSessionProvider.overrideWith(() => stub)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VocabularyPracticeClipBody)),
    );
    expect(container.read(playerSurfaceRegistryProvider), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('echo practice phase does not claim video surface', () {
    final state = _baseState(phase: ReviewPracticePhase.echo);
    expect(state.claimsVideoSurface, isFalse);
    expect(state.practiceOwnsVideoStage, isFalse);
    expect(state.practiceMode, ReviewPracticeMode.echo);
  });

  test('echo modal enables recorder controls without a player session', () {
    final state = _baseState(phase: ReviewPracticePhase.echo);
    final panel = buildVocabularyEchoRecorder(
      contextItem: state.currentPrimaryContext!,
      language: state.currentItem!.language,
    );

    expect(panel.echoActive, isTrue);
    expect(panel.mediaId, 'media-1');
    expect(panel.startSec, 1.5);
    expect(panel.endSec, 4.0);
  });
}
