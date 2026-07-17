import 'package:enjoy_player/features/vocabulary/domain/vocabulary_item_conflict.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItemConflictSide _side({
  String word = 'hello',
  String status = 'learning',
  double easeFactor = 2.5,
  int interval = 1,
  DateTime? nextReviewAt,
  int reviewsCount = 1,
  DateTime? lastReviewedAt,
  String? explanation,
  int contextsCount = 1,
  required DateTime updatedAt,
}) {
  return VocabularyItemConflictSide(
    word: word,
    status: status,
    easeFactor: easeFactor,
    interval: interval,
    nextReviewAt: nextReviewAt ?? updatedAt,
    reviewsCount: reviewsCount,
    lastReviewedAt: lastReviewedAt,
    explanation: explanation,
    contextsCount: contextsCount,
    updatedAt: updatedAt,
  );
}

void main() {
  group('localVocabularySrsIsNewer', () {
    test('both reviewed: later lastReviewedAt wins', () {
      expect(
        localVocabularySrsIsNewer(
          localLastReviewedAt: DateTime.utc(2026, 1, 2),
          serverLastReviewedAt: DateTime.utc(2026, 1, 1),
          localReviewsCount: 1,
          serverReviewsCount: 99,
        ),
        isTrue,
      );
      expect(
        localVocabularySrsIsNewer(
          localLastReviewedAt: DateTime.utc(2026, 1, 1),
          serverLastReviewedAt: DateTime.utc(2026, 1, 2),
          localReviewsCount: 99,
          serverReviewsCount: 1,
        ),
        isFalse,
      );
    });

    test('only local reviewed: local wins regardless of reviewsCount', () {
      expect(
        localVocabularySrsIsNewer(
          localLastReviewedAt: DateTime.utc(2026, 1, 1),
          serverLastReviewedAt: null,
          localReviewsCount: 0,
          serverReviewsCount: 50,
        ),
        isTrue,
      );
    });

    test('only server reviewed: server wins regardless of reviewsCount', () {
      expect(
        localVocabularySrsIsNewer(
          localLastReviewedAt: null,
          serverLastReviewedAt: DateTime.utc(2026, 1, 1),
          localReviewsCount: 50,
          serverReviewsCount: 0,
        ),
        isFalse,
      );
    });

    test('neither reviewed: higher reviewsCount wins', () {
      expect(
        localVocabularySrsIsNewer(
          localLastReviewedAt: null,
          serverLastReviewedAt: null,
          localReviewsCount: 3,
          serverReviewsCount: 2,
        ),
        isTrue,
      );
      expect(
        localVocabularySrsIsNewer(
          localLastReviewedAt: null,
          serverLastReviewedAt: null,
          localReviewsCount: 2,
          serverReviewsCount: 2,
        ),
        isFalse,
      );
    });
  });

  group('resolveVocabularyItemConflict', () {
    test('server SRS newer: server row wins wholesale', () {
      final local = _side(
        word: 'Local Word',
        lastReviewedAt: DateTime.utc(2026, 1, 1),
        reviewsCount: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final server = _side(
        word: 'Server Word',
        status: 'reviewing',
        lastReviewedAt: DateTime.utc(2026, 1, 5),
        reviewsCount: 2,
        explanation: 'server-explanation',
        updatedAt: DateTime.utc(2026, 1, 5),
      );

      final result = resolveVocabularyItemConflict(
        local: local,
        server: server,
      );

      expect(result.keptLocalSrs, isFalse);
      expect(result.word, 'Server Word');
      expect(result.status, 'reviewing');
      expect(result.reviewsCount, 2);
      expect(result.lastReviewedAt, DateTime.utc(2026, 1, 5));
      expect(result.explanation, 'server-explanation');
      expect(result.serverUpdatedAt, DateTime.utc(2026, 1, 5));
    });

    test(
      'local SRS newer and server.updatedAt not newer: local wins fully',
      () {
        final local = _side(
          word: 'Local Word',
          explanation: 'local-explanation',
          lastReviewedAt: DateTime.utc(2026, 2, 1),
          reviewsCount: 5,
          updatedAt: DateTime.utc(2026, 2, 1),
        );
        final server = _side(
          word: 'Server Word',
          explanation: 'server-explanation',
          lastReviewedAt: DateTime.utc(2026, 1, 1),
          reviewsCount: 1,
          updatedAt: DateTime.utc(2026, 1, 15),
        );

        final result = resolveVocabularyItemConflict(
          local: local,
          server: server,
        );

        expect(result.keptLocalSrs, isTrue);
        expect(result.reviewsCount, 5);
        expect(result.lastReviewedAt, DateTime.utc(2026, 2, 1));
        // server.updatedAt (Jan 15) is before local's SRS reference (Feb 1
        // lastReviewedAt) — local metadata wins too.
        expect(result.word, 'Local Word');
        expect(result.explanation, 'local-explanation');
        expect(result.serverUpdatedAt, DateTime.utc(2026, 2, 1));
      },
    );

    test('local SRS newer but server metadata newer than local SRS reference: '
        'adopt server word/explanation, keep local SRS fields', () {
      final local = _side(
        word: 'Local Word',
        explanation: 'local-explanation',
        easeFactor: 3.0,
        interval: 10,
        lastReviewedAt: DateTime.utc(2026, 1, 1),
        reviewsCount: 5,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final server = _side(
        word: 'Server Word',
        explanation: 'server-explanation',
        lastReviewedAt: DateTime.utc(2025, 12, 1),
        reviewsCount: 1,
        // Newer than local's lastReviewedAt (the SRS reference).
        updatedAt: DateTime.utc(2026, 1, 10),
      );

      final result = resolveVocabularyItemConflict(
        local: local,
        server: server,
      );

      expect(result.keptLocalSrs, isTrue);
      expect(result.easeFactor, 3.0);
      expect(result.interval, 10);
      expect(result.reviewsCount, 5);
      expect(result.lastReviewedAt, DateTime.utc(2026, 1, 1));
      expect(result.word, 'Server Word');
      expect(result.explanation, 'server-explanation');
      expect(result.serverUpdatedAt, DateTime.utc(2026, 1, 1));
    });

    test('local SRS newer with no lastReviewedAt: SRS reference falls back to '
        'local.updatedAt', () {
      final local = _side(
        word: 'Local Word',
        lastReviewedAt: null,
        reviewsCount: 3,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final server = _side(
        word: 'Server Word',
        lastReviewedAt: null,
        reviewsCount: 1,
        updatedAt: DateTime.utc(2026, 1, 5),
      );

      final result = resolveVocabularyItemConflict(
        local: local,
        server: server,
      );

      expect(result.keptLocalSrs, isTrue);
      expect(result.reviewsCount, 3);
      // server.updatedAt (Jan 5) is after local.updatedAt (Jan 1) since
      // local never reviewed — adopt server word.
      expect(result.word, 'Server Word');
    });
  });
}
