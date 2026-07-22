import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // --------------------------------------------------------------------------
  // Enums
  // --------------------------------------------------------------------------
  group('VocabularyStatus', () {
    test('has correct wire values', () {
      expect(VocabularyStatus.new_.wire, 'new');
      expect(VocabularyStatus.learning.wire, 'learning');
      expect(VocabularyStatus.reviewing.wire, 'reviewing');
      expect(VocabularyStatus.mastered.wire, 'mastered');
    });

    test('fromWire resolves all values', () {
      expect(VocabularyStatus.fromWire('new'), VocabularyStatus.new_);
      expect(VocabularyStatus.fromWire('learning'), VocabularyStatus.learning);
      expect(
        VocabularyStatus.fromWire('reviewing'),
        VocabularyStatus.reviewing,
      );
      expect(VocabularyStatus.fromWire('mastered'), VocabularyStatus.mastered);
    });

    test('fromWire throws for unknown wire value', () {
      expect(() => VocabularyStatus.fromWire('unknown'), throwsArgumentError);
    });

    test('fromWire throws for empty string', () {
      expect(() => VocabularyStatus.fromWire(''), throwsArgumentError);
    });
  });

  group('VocabularyRating', () {
    test('has correct integer values', () {
      expect(VocabularyRating.dontKnow.value, 0);
      expect(VocabularyRating.know.value, 1);
      expect(VocabularyRating.knowWell.value, 2);
    });

    test('fromValue resolves all values', () {
      expect(VocabularyRating.fromValue(0), VocabularyRating.dontKnow);
      expect(VocabularyRating.fromValue(1), VocabularyRating.know);
      expect(VocabularyRating.fromValue(2), VocabularyRating.knowWell);
    });

    test('fromValue throws for negative value', () {
      expect(() => VocabularyRating.fromValue(-1), throwsArgumentError);
    });

    test('fromValue throws for out-of-range value', () {
      expect(() => VocabularyRating.fromValue(3), throwsArgumentError);
    });
  });

  group('VocabularySourceType', () {
    test('has correct wire values', () {
      expect(VocabularySourceType.video.wire, 'Video');
      expect(VocabularySourceType.audio.wire, 'Audio');
      expect(VocabularySourceType.ebook.wire, 'Ebook');
    });

    test('fromWire resolves all values', () {
      expect(
        VocabularySourceType.fromWire('Video'),
        VocabularySourceType.video,
      );
      expect(
        VocabularySourceType.fromWire('Audio'),
        VocabularySourceType.audio,
      );
      expect(
        VocabularySourceType.fromWire('Ebook'),
        VocabularySourceType.ebook,
      );
    });

    test('fromWire is case-sensitive', () {
      expect(() => VocabularySourceType.fromWire('video'), throwsArgumentError);
    });

    test('fromWire throws for unknown wire value', () {
      expect(
        () => VocabularySourceType.fromWire('Podcast'),
        throwsArgumentError,
      );
    });
  });

  // --------------------------------------------------------------------------
  // MediaLocator
  // --------------------------------------------------------------------------
  group('MediaLocator', () {
    test('constructs with required fields', () {
      const locator = MediaLocator(start: 1000, duration: 5000);
      expect(locator.start, 1000);
      expect(locator.duration, 5000);
    });

    test('toJson produces expected map', () {
      const locator = MediaLocator(start: 1234, duration: 5678);
      expect(locator.toJson(), {
        'type': 'media',
        'start': 1234,
        'duration': 5678,
      });
    });

    test('fromJson parses valid map', () {
      final locator = MediaLocator.fromJson({
        'type': 'media',
        'start': 42,
        'duration': 99,
      });
      expect(locator.start, 42);
      expect(locator.duration, 99);
    });

    test('fromJson accepts num values (double-coerced from JSON)', () {
      final locator = MediaLocator.fromJson({
        'type': 'media',
        'start': 42.0,
        'duration': 99.0,
      });
      expect(locator.start, 42);
      expect(locator.duration, 99);
    });

    test('fromJson throws when type is wrong', () {
      expect(
        () =>
            MediaLocator.fromJson({'type': 'ebook', 'start': 0, 'duration': 0}),
        throwsFormatException,
      );
    });

    test('fromJson throws when type is missing', () {
      expect(
        () => MediaLocator.fromJson({'start': 0, 'duration': 0}),
        throwsFormatException,
      );
    });

    test('supports value equality', () {
      const a = MediaLocator(start: 100, duration: 200);
      const b = MediaLocator(start: 100, duration: 200);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when start differs', () {
      const a = MediaLocator(start: 100, duration: 200);
      const b = MediaLocator(start: 101, duration: 200);
      expect(a, isNot(b));
    });

    test('inequality when duration differs', () {
      const a = MediaLocator(start: 100, duration: 200);
      const b = MediaLocator(start: 100, duration: 201);
      expect(a, isNot(b));
    });

    test('round-trips through toJson/fromJson', () {
      const original = MediaLocator(start: 777, duration: 888);
      final decoded = MediaLocator.fromJson(original.toJson());
      expect(decoded, original);
    });
  });

  // --------------------------------------------------------------------------
  // EbookLocatorLocations
  // --------------------------------------------------------------------------
  group('EbookLocatorLocations', () {
    test('supports all-null fields', () {
      const loc = EbookLocatorLocations();
      expect(loc.fragments, isNull);
      expect(loc.progression, isNull);
      expect(loc.totalProgression, isNull);
      expect(loc.position, isNull);
    });

    test('toJson omits null fields', () {
      const loc = EbookLocatorLocations();
      expect(loc.toJson(), isEmpty);
    });

    test('fromJson parses string fragments and numeric fields', () {
      final loc = EbookLocatorLocations.fromJson({
        'fragments': ['p1', 'p2'],
        'progression': 0.5,
        'totalProgression': 0.75,
        'position': 3,
      });
      expect(loc.fragments, ['p1', 'p2']);
      expect(loc.progression, 0.5);
      expect(loc.totalProgression, 0.75);
      expect(loc.position, 3);
    });

    test('fromJson coerces integer-typed fields when passed as doubles', () {
      final loc = EbookLocatorLocations.fromJson({
        'progression': 0.5,
        'totalProgression': 0.5,
        'position': 3.0,
      });
      expect(loc.progression, 0.5);
      expect(loc.totalProgression, 0.5);
      expect(loc.position, 3);
    });

    test('fromJson handles null fragments', () {
      final loc = EbookLocatorLocations.fromJson({'fragments': null});
      expect(loc.fragments, isNull);
    });

    test('round-trips through toJson/fromJson with all fields', () {
      const original = EbookLocatorLocations(
        fragments: ['chapter1'],
        progression: 0.3,
        totalProgression: 0.6,
        position: 5,
      );
      final decoded = EbookLocatorLocations.fromJson(original.toJson());
      expect(decoded.fragments, ['chapter1']);
      expect(decoded.progression, 0.3);
      expect(decoded.totalProgression, 0.6);
      expect(decoded.position, 5);
    });
  });

  // --------------------------------------------------------------------------
  // EbookLocator
  // --------------------------------------------------------------------------
  group('EbookLocator', () {
    test('constructs with required fields', () {
      const locator = EbookLocator(
        href: 'chapter01.xhtml',
        locatorType: 'application/xhtml+xml',
      );
      expect(locator.href, 'chapter01.xhtml');
      expect(locator.locatorType, 'application/xhtml+xml');
      expect(locator.title, isNull);
      expect(locator.locations, isNull);
      expect(locator.text, isNull);
    });

    test('toJson omits null optional fields', () {
      const locator = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'text/html',
      );
      expect(locator.toJson(), {
        'type': 'ebook',
        'href': 'ch01.xhtml',
        'locatorType': 'text/html',
      });
    });

    test('toJson includes non-null optionals', () {
      const locator = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'text/html',
        title: 'Chapter 1',
        text: 'Hello world',
      );
      expect(locator.toJson(), {
        'type': 'ebook',
        'href': 'ch01.xhtml',
        'locatorType': 'text/html',
        'title': 'Chapter 1',
        'text': 'Hello world',
      });
    });

    test('fromJson parses minimal map', () {
      final locator = EbookLocator.fromJson({
        'type': 'ebook',
        'href': 'ch02.xhtml',
        'locatorType': 'application/xhtml+xml',
      });
      expect(locator.href, 'ch02.xhtml');
      expect(locator.locatorType, 'application/xhtml+xml');
      expect(locator.title, isNull);
      expect(locator.locations, isNull);
      expect(locator.text, isNull);
    });

    test('fromJson parses map with locations', () {
      final locator = EbookLocator.fromJson({
        'type': 'ebook',
        'href': 'ch03.xhtml',
        'locatorType': 'application/xhtml+xml',
        'locations': {
          'fragments': ['p1'],
          'progression': 0.1,
        },
      });
      expect(locator.locations, isNotNull);
      expect(locator.locations!.fragments, ['p1']);
      expect(locator.locations!.progression, 0.1);
    });

    test('fromJson throws when type is wrong', () {
      expect(
        () => EbookLocator.fromJson({
          'type': 'media',
          'href': 'ch01.xhtml',
          'locatorType': 'text/html',
        }),
        throwsFormatException,
      );
    });

    test('round-trips through toJson/fromJson with all optionals', () {
      const original = EbookLocator(
        href: 'ch04.xhtml',
        locatorType: 'text/html',
        title: 'Chapter 4',
        locations: EbookLocatorLocations(position: 2),
        text: 'Some text',
      );
      final decoded = EbookLocator.fromJson(original.toJson());
      expect(decoded.href, 'ch04.xhtml');
      expect(decoded.locatorType, 'text/html');
      expect(decoded.title, 'Chapter 4');
      expect(decoded.locations?.position, 2);
      expect(decoded.text, 'Some text');
    });
  });

  // --------------------------------------------------------------------------
  // VocabularyItem
  // --------------------------------------------------------------------------
  group('VocabularyItem', () {
    final fixedNow = DateTime.utc(2024, 6, 15);

    VocabularyItem baseItem() => VocabularyItem(
      id: 'hello-en-zh',
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      status: VocabularyStatus.new_,
      easeFactor: 2.5,
      interval: 0,
      nextReviewAt: fixedNow,
      reviewsCount: 0,
      contextsCount: 1,
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    test('constructor assigns fields', () {
      final item = baseItem();
      expect(item.id, 'hello-en-zh');
      expect(item.word, 'hello');
      expect(item.language, 'en');
      expect(item.targetLanguage, 'zh');
      expect(item.status, VocabularyStatus.new_);
      expect(item.easeFactor, 2.5);
      expect(item.interval, 0);
      expect(item.nextReviewAt, fixedNow);
      expect(item.reviewsCount, 0);
      expect(item.contextsCount, 1);
      expect(item.createdAt, fixedNow);
      expect(item.updatedAt, fixedNow);
      expect(item.lastReviewedAt, isNull);
      expect(item.explanation, isNull);
      expect(item.syncStatus, isNull);
      expect(item.serverUpdatedAt, isNull);
    });

    test('copyWith overrides specified fields', () {
      final item = baseItem();
      final later = DateTime.utc(2024, 7, 1);
      final copy = item.copyWith(
        status: VocabularyStatus.learning,
        easeFactor: 2.0,
        interval: 1,
        reviewsCount: 1,
        contextsCount: 2,
        lastReviewedAt: later,
        syncStatus: 'synced',
      );
      expect(copy.status, VocabularyStatus.learning);
      expect(copy.easeFactor, 2.0);
      expect(copy.interval, 1);
      expect(copy.reviewsCount, 1);
      expect(copy.contextsCount, 2);
      expect(copy.lastReviewedAt, later);
      expect(copy.syncStatus, 'synced');
      // Unchanged fields preserved
      expect(copy.id, 'hello-en-zh');
      expect(copy.word, 'hello');
    });

    test('copyWith clearLastReviewedAt clears the field', () {
      final item = baseItem().copyWith(lastReviewedAt: fixedNow);
      expect(item.lastReviewedAt, fixedNow);

      final cleared = item.copyWith(clearLastReviewedAt: true);
      expect(cleared.lastReviewedAt, isNull);
    });

    test('copyWith clearLastReviewedAt: false keeps existing value', () {
      final item = baseItem().copyWith(lastReviewedAt: fixedNow);
      final kept = item.copyWith(clearLastReviewedAt: false);
      expect(kept.lastReviewedAt, fixedNow);
    });
  });

  // --------------------------------------------------------------------------
  // VocabularyContext
  // --------------------------------------------------------------------------
  group('VocabularyContext', () {
    final fixedNow = DateTime.utc(2024, 6, 15);

    VocabularyContext baseContext() => VocabularyContext(
      id: 'ctx-1',
      vocabularyItemId: 'hello-en-zh',
      text: 'Hello world',
      sourceType: VocabularySourceType.video,
      sourceId: 'vid-123',
      locator: const MediaLocator(start: 1000, duration: 5000),
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    test('constructor assigns fields', () {
      final ctx = baseContext();
      expect(ctx.id, 'ctx-1');
      expect(ctx.vocabularyItemId, 'hello-en-zh');
      expect(ctx.text, 'Hello world');
      expect(ctx.sourceType, VocabularySourceType.video);
      expect(ctx.sourceId, 'vid-123');
      expect(ctx.locator, isNotNull);
      expect(ctx.ebookLocator, isNull);
      expect(ctx.createdAt, fixedNow);
      expect(ctx.updatedAt, fixedNow);
      expect(ctx.explanation, isNull);
      expect(ctx.syncStatus, isNull);
      expect(ctx.serverUpdatedAt, isNull);
    });

    test('copyWith overrides specified fields', () {
      final ctx = baseContext();
      final copy = ctx.copyWith(
        text: '¡Hola mundo!',
        sourceType: VocabularySourceType.audio,
        sourceId: 'aud-456',
        explanation: 'A greeting',
      );
      expect(copy.text, '¡Hola mundo!');
      expect(copy.sourceType, VocabularySourceType.audio);
      expect(copy.sourceId, 'aud-456');
      expect(copy.explanation, 'A greeting');
      expect(copy.id, 'ctx-1'); // unchanged
    });

    test('copyWith clearExplanation clears the field', () {
      final ctx = baseContext().copyWith(explanation: 'some explanation');
      expect(ctx.explanation, 'some explanation');

      final cleared = ctx.copyWith(clearExplanation: true);
      expect(cleared.explanation, isNull);
    });

    test('copyWith clearExplanation: false keeps existing value', () {
      final ctx = baseContext().copyWith(explanation: 'keep me');
      expect(ctx.explanation, 'keep me');

      final kept = ctx.copyWith(clearExplanation: false);
      expect(kept.explanation, 'keep me');
    });

    test('constructor accepts ebookLocator variant', () {
      final ctx = VocabularyContext(
        id: 'ctx-2',
        vocabularyItemId: 'bonjour-en-zh',
        text: 'Bonjour',
        sourceType: VocabularySourceType.ebook,
        sourceId: 'book-1',
        locator: null,
        ebookLocator: const EbookLocator(
          href: 'page1.xhtml',
          locatorType: 'application/xhtml+xml',
        ),
        createdAt: fixedNow,
        updatedAt: fixedNow,
      );
      expect(ctx.sourceType, VocabularySourceType.ebook);
      expect(ctx.ebookLocator, isNotNull);
      expect(ctx.ebookLocator!.href, 'page1.xhtml');
      expect(ctx.locator, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // VocabularyReview
  // --------------------------------------------------------------------------
  group('VocabularyReview', () {
    test('constructor assigns all fields', () {
      final now = DateTime.utc(2024, 6, 15, 12, 30);
      final review = VocabularyReview(
        id: 'review-1',
        vocabularyItemId: 'hello-en-zh',
        rating: VocabularyRating.know,
        at: now,
        easeFactorBefore: 2.5,
        intervalBefore: 0,
        statusBefore: VocabularyStatus.new_,
        reviewsCountBefore: 0,
        nextReviewAtBefore: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(review.id, 'review-1');
      expect(review.vocabularyItemId, 'hello-en-zh');
      expect(review.rating, VocabularyRating.know);
      expect(review.at, now);
      expect(review.easeFactorBefore, 2.5);
      expect(review.intervalBefore, 0);
      expect(review.statusBefore, VocabularyStatus.new_);
      expect(review.reviewsCountBefore, 0);
      expect(review.nextReviewAtBefore, now);
      expect(review.lastReviewedAtBefore, isNull);
      expect(review.syncStatus, isNull);
    });

    test('constructor accepts optional fields', () {
      final now = DateTime.utc(2024, 6, 15);
      final review = VocabularyReview(
        id: 'review-2',
        vocabularyItemId: 'hello-en-zh',
        rating: VocabularyRating.knowWell,
        at: now,
        easeFactorBefore: 2.0,
        intervalBefore: 5,
        statusBefore: VocabularyStatus.learning,
        reviewsCountBefore: 2,
        nextReviewAtBefore: now,
        lastReviewedAtBefore: now,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );
      expect(review.lastReviewedAtBefore, now);
      expect(review.syncStatus, 'synced');
    });
  });

  // --------------------------------------------------------------------------
  // AddVocabularyResult
  // --------------------------------------------------------------------------
  group('AddVocabularyResult', () {
    test('constructor assigns fields', () {
      final now = DateTime.utc(2024, 6, 15);
      final item = VocabularyItem(
        id: 'hello-en-zh',
        word: 'hello',
        language: 'en',
        targetLanguage: 'zh',
        status: VocabularyStatus.new_,
        easeFactor: 2.5,
        interval: 0,
        nextReviewAt: now,
        reviewsCount: 0,
        contextsCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      final context = VocabularyContext(
        id: 'ctx-1',
        vocabularyItemId: 'hello-en-zh',
        text: 'Hello world',
        sourceType: VocabularySourceType.video,
        sourceId: 'vid-123',
        locator: const MediaLocator(start: 1000, duration: 5000),
        createdAt: now,
        updatedAt: now,
      );
      final result = AddVocabularyResult(
        item: item,
        context: context,
        isNewContext: true,
      );
      expect(result.item, item);
      expect(result.context, context);
      expect(result.isNewContext, isTrue);
    });

    test('isNewContext can be false', () {
      final now = DateTime.utc(2024, 6, 15);
      final item = VocabularyItem(
        id: 'hello-en-zh',
        word: 'hello',
        language: 'en',
        targetLanguage: 'zh',
        status: VocabularyStatus.new_,
        easeFactor: 2.5,
        interval: 0,
        nextReviewAt: now,
        reviewsCount: 0,
        contextsCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      final result = AddVocabularyResult(
        item: item,
        context: VocabularyContext(
          id: 'ctx-1',
          vocabularyItemId: 'hello-en-zh',
          text: 'Hello world',
          sourceType: VocabularySourceType.video,
          sourceId: 'vid-123',
          locator: const MediaLocator(start: 1000, duration: 5000),
          createdAt: now,
          updatedAt: now,
        ),
        isNewContext: false,
      );
      expect(result.isNewContext, isFalse);
    });
  });

  // --------------------------------------------------------------------------
  // ReviewUpdate
  // --------------------------------------------------------------------------
  group('ReviewUpdate', () {
    test('constructor assigns all fields', () {
      final now = DateTime.utc(2024, 6, 16);
      final update = ReviewUpdate(
        status: VocabularyStatus.learning,
        easeFactor: 2.5,
        interval: 1,
        nextReviewAt: now,
        reviewsCount: 1,
        lastReviewedAt: now,
      );
      expect(update.status, VocabularyStatus.learning);
      expect(update.easeFactor, 2.5);
      expect(update.interval, 1);
      expect(update.nextReviewAt, now);
      expect(update.reviewsCount, 1);
      expect(update.lastReviewedAt, now);
    });
  });
}
