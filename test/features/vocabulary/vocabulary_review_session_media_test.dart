import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mediaLocatorWindow', () {
    test('converts ms locator to seconds', () {
      const locator = MediaLocator(start: 1500, duration: 2500);
      final window = mediaLocatorWindow(locator);
      expect(window.startSec, 1.5);
      expect(window.endSec, 4.0);
    });
  });

  group('vocabularyContextSupportsMediaActions', () {
    test('requires media locator and video/audio source', () {
      final media = VocabularyContext(
        id: 'c1',
        vocabularyItemId: 'i1',
        text: 'hi',
        sourceType: VocabularySourceType.video,
        sourceId: 'v1',
        locator: const MediaLocator(start: 0, duration: 1000),
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2020),
      );
      expect(vocabularyContextSupportsMediaActions(media), isTrue);

      final ebook = VocabularyContext(
        id: 'c2',
        vocabularyItemId: 'i1',
        text: 'hi',
        sourceType: VocabularySourceType.ebook,
        sourceId: 'e1',
        locator: null,
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2020),
      );
      expect(vocabularyContextSupportsMediaActions(ebook), isFalse);
    });
  });

  group('takeMediaHandoff', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('clears session and returns seek window', () async {
      final repo = VocabularyRepository(db);
      await repo.addWithContext(
        word: 'hello',
        language: 'en',
        targetLanguage: 'zh',
        text: 'Hello world.',
        sourceType: VocabularySourceType.video,
        sourceId: 'media-42',
        mediaLocator: const MediaLocator(start: 3000, duration: 2000),
        now: DateTime.utc(2020, 1, 1),
      );

      final session = container.read(vocabularyReviewSessionProvider.notifier);
      await session.start(
        const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
        now: DateTime.utc(2030, 1, 1),
      );
      expect(
        container.read(vocabularyReviewSessionProvider).hasActiveSession,
        isTrue,
      );

      final handoff = session.takeMediaHandoff(activateEcho: true);
      expect(handoff, isNotNull);
      expect(handoff!.mediaId, 'media-42');
      expect(handoff.startSec, 3.0);
      expect(handoff.endSec, 5.0);
      expect(handoff.activateEcho, isTrue);
      expect(
        container.read(vocabularyReviewSessionProvider).hasActiveSession,
        isFalse,
      );
    });

    test('open-in-player style handoff does not activate echo flag', () async {
      final repo = VocabularyRepository(db);
      await repo.addWithContext(
        word: 'hello',
        language: 'en',
        targetLanguage: 'zh',
        text: 'Hello world.',
        sourceType: VocabularySourceType.audio,
        sourceId: 'a1',
        mediaLocator: const MediaLocator(start: 0, duration: 500),
        now: DateTime.utc(2020, 1, 1),
      );

      final session = container.read(vocabularyReviewSessionProvider.notifier);
      await session.start(
        const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
        now: DateTime.utc(2030, 1, 1),
      );
      final handoff = session.takeMediaHandoff(activateEcho: false);
      expect(handoff!.activateEcho, isFalse);
    });
  });
}
