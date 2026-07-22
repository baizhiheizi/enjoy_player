import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VocabularyStatus.fromWire', () {
    test('parses all valid wire values', () {
      expect(VocabularyStatus.fromWire('new'), VocabularyStatus.new_);
      expect(VocabularyStatus.fromWire('learning'), VocabularyStatus.learning);
      expect(
        VocabularyStatus.fromWire('reviewing'),
        VocabularyStatus.reviewing,
      );
      expect(VocabularyStatus.fromWire('mastered'), VocabularyStatus.mastered);
    });

    test('throws on unknown wire value', () {
      expect(() => VocabularyStatus.fromWire('unknown'), throwsArgumentError);
      expect(() => VocabularyStatus.fromWire(''), throwsArgumentError);
      expect(() => VocabularyStatus.fromWire('NEW'), throwsArgumentError);
    });
  });

  group('VocabularyRating.fromValue', () {
    test('parses all valid values', () {
      expect(VocabularyRating.fromValue(0), VocabularyRating.dontKnow);
      expect(VocabularyRating.fromValue(1), VocabularyRating.know);
      expect(VocabularyRating.fromValue(2), VocabularyRating.knowWell);
    });

    test('throws on invalid value', () {
      expect(() => VocabularyRating.fromValue(3), throwsArgumentError);
      expect(() => VocabularyRating.fromValue(-1), throwsArgumentError);
      expect(() => VocabularyRating.fromValue(99), throwsArgumentError);
    });
  });

  group('VocabularySourceType.fromWire', () {
    test('parses all valid wire values', () {
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

    test('throws on unknown wire value', () {
      expect(() => VocabularySourceType.fromWire('video'), throwsArgumentError);
      expect(() => VocabularySourceType.fromWire(''), throwsArgumentError);
      expect(
        () => VocabularySourceType.fromWire('Podcast'),
        throwsArgumentError,
      );
    });
  });

  group('MediaLocator', () {
    test('fromJson parses valid media locator', () {
      final locator = MediaLocator.fromJson({
        'type': 'media',
        'start': 1000,
        'duration': 5000,
      });
      expect(locator.start, 1000);
      expect(locator.duration, 5000);
    });

    test('fromJson accepts num types (double)', () {
      final locator = MediaLocator.fromJson({
        'type': 'media',
        'start': 1000.0,
        'duration': 5000.0,
      });
      expect(locator.start, 1000);
      expect(locator.duration, 5000);
    });

    test('fromJson throws on wrong type field', () {
      expect(
        () => MediaLocator.fromJson({
          'type': 'ebook',
          'start': 0,
          'duration': 100,
        }),
        throwsFormatException,
      );
    });

    test('toJson round-trips', () {
      const locator = MediaLocator(start: 42, duration: 99);
      final json = locator.toJson();
      expect(json['type'], 'media');
      expect(json['start'], 42);
      expect(json['duration'], 99);
      expect(MediaLocator.fromJson(json), locator);
    });

    test('equality and hashCode', () {
      const a = MediaLocator(start: 10, duration: 20);
      const b = MediaLocator(start: 10, duration: 20);
      const c = MediaLocator(start: 10, duration: 30);
      const d = MediaLocator(start: 11, duration: 20);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });

  group('EbookLocator', () {
    test('fromJson parses minimal ebook locator', () {
      final locator = EbookLocator.fromJson({
        'type': 'ebook',
        'href': 'ch01.xhtml',
        'locatorType': 'application/xhtml+xml',
      });
      expect(locator.href, 'ch01.xhtml');
      expect(locator.locatorType, 'application/xhtml+xml');
      expect(locator.title, isNull);
      expect(locator.locations, isNull);
      expect(locator.text, isNull);
    });

    test('fromJson parses full ebook locator with locations', () {
      final locator = EbookLocator.fromJson({
        'type': 'ebook',
        'href': 'ch02.xhtml',
        'locatorType': 'application/xhtml+xml',
        'title': 'Chapter 2',
        'text': 'Some highlighted text',
        'locations': {
          'fragments': ['frag1', 'frag2'],
          'progression': 0.5,
          'totalProgression': 0.25,
          'position': 42,
        },
      });
      expect(locator.href, 'ch02.xhtml');
      expect(locator.title, 'Chapter 2');
      expect(locator.text, 'Some highlighted text');
      expect(locator.locations, isNotNull);
      expect(locator.locations!.fragments, ['frag1', 'frag2']);
      expect(locator.locations!.progression, 0.5);
      expect(locator.locations!.totalProgression, 0.25);
      expect(locator.locations!.position, 42);
    });

    test('fromJson throws on wrong type field', () {
      expect(
        () => EbookLocator.fromJson({
          'type': 'media',
          'href': 'ch01.xhtml',
          'locatorType': 'application/xhtml+xml',
        }),
        throwsFormatException,
      );
    });

    test('toJson omits null optional fields', () {
      const locator = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'application/xhtml+xml',
      );
      final json = locator.toJson();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('locations'), isFalse);
      expect(json.containsKey('text'), isFalse);
      expect(json['type'], 'ebook');
      expect(json['href'], 'ch01.xhtml');
    });

    test('toJson includes non-null optional fields', () {
      const locator = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'application/xhtml+xml',
        title: 'Ch 1',
        text: 'hello',
        locations: EbookLocatorLocations(position: 5),
      );
      final json = locator.toJson();
      expect(json['title'], 'Ch 1');
      expect(json['text'], 'hello');
      expect(json['locations'], isA<Map>());
    });
  });

  group('EbookLocatorLocations', () {
    test('fromJson parses all fields', () {
      final loc = EbookLocatorLocations.fromJson({
        'fragments': ['a', 'b'],
        'progression': 0.75,
        'totalProgression': 0.3,
        'position': 10,
      });
      expect(loc.fragments, ['a', 'b']);
      expect(loc.progression, 0.75);
      expect(loc.totalProgression, 0.3);
      expect(loc.position, 10);
    });

    test('fromJson handles missing fields as null', () {
      final loc = EbookLocatorLocations.fromJson({});
      expect(loc.fragments, isNull);
      expect(loc.progression, isNull);
      expect(loc.totalProgression, isNull);
      expect(loc.position, isNull);
    });

    test('toJson omits null fields', () {
      const loc = EbookLocatorLocations(position: 3);
      final json = loc.toJson();
      expect(json.containsKey('fragments'), isFalse);
      expect(json.containsKey('progression'), isFalse);
      expect(json.containsKey('totalProgression'), isFalse);
      expect(json['position'], 3);
    });
  });

  group('VocabularyItem.copyWith', () {
    final base = VocabularyItem(
      id: 'id1',
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      status: VocabularyStatus.learning,
      easeFactor: 2.5,
      interval: 3,
      nextReviewAt: DateTime.utc(2024, 6, 1),
      reviewsCount: 2,
      lastReviewedAt: DateTime.utc(2024, 5, 30),
      contextsCount: 1,
      explanation: 'expl',
      syncStatus: 'pending',
      serverUpdatedAt: DateTime.utc(2024, 5, 29),
      createdAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 5, 30),
    );

    test('returns identical values when no args passed', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.word, base.word);
      expect(copy.language, base.language);
      expect(copy.targetLanguage, base.targetLanguage);
      expect(copy.status, base.status);
      expect(copy.easeFactor, base.easeFactor);
      expect(copy.interval, base.interval);
      expect(copy.nextReviewAt, base.nextReviewAt);
      expect(copy.reviewsCount, base.reviewsCount);
      expect(copy.lastReviewedAt, base.lastReviewedAt);
      expect(copy.contextsCount, base.contextsCount);
      expect(copy.explanation, base.explanation);
      expect(copy.syncStatus, base.syncStatus);
      expect(copy.serverUpdatedAt, base.serverUpdatedAt);
      expect(copy.createdAt, base.createdAt);
      expect(copy.updatedAt, base.updatedAt);
    });

    test('overrides specified fields', () {
      final copy = base.copyWith(
        word: 'world',
        status: VocabularyStatus.mastered,
        easeFactor: 1.8,
        interval: 10,
        reviewsCount: 5,
      );
      expect(copy.word, 'world');
      expect(copy.status, VocabularyStatus.mastered);
      expect(copy.easeFactor, 1.8);
      expect(copy.interval, 10);
      expect(copy.reviewsCount, 5);
      expect(copy.id, 'id1');
    });

    test('clearLastReviewedAt sets lastReviewedAt to null', () {
      expect(base.lastReviewedAt, isNotNull);
      final copy = base.copyWith(clearLastReviewedAt: true);
      expect(copy.lastReviewedAt, isNull);
    });

    test('lastReviewedAt param takes precedence over clearLastReviewedAt', () {
      final newDate = DateTime.utc(2024, 6, 15);
      final copy = base.copyWith(
        lastReviewedAt: newDate,
        clearLastReviewedAt: true,
      );
      expect(copy.lastReviewedAt, isNull);
    });
  });

  group('VocabularyContext.copyWith', () {
    final base = VocabularyContext(
      id: 'ctx1',
      vocabularyItemId: 'item1',
      text: 'Hello world',
      sourceType: VocabularySourceType.video,
      sourceId: 'vid1',
      locator: const MediaLocator(start: 0, duration: 1000),
      ebookLocator: null,
      explanation: 'some explanation',
      syncStatus: 'synced',
      serverUpdatedAt: DateTime.utc(2024, 3, 1),
      createdAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 3, 1),
    );

    test('returns identical values when no args passed', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.vocabularyItemId, base.vocabularyItemId);
      expect(copy.text, base.text);
      expect(copy.sourceType, base.sourceType);
      expect(copy.sourceId, base.sourceId);
      expect(copy.locator, base.locator);
      expect(copy.ebookLocator, base.ebookLocator);
      expect(copy.explanation, base.explanation);
      expect(copy.syncStatus, base.syncStatus);
      expect(copy.serverUpdatedAt, base.serverUpdatedAt);
      expect(copy.createdAt, base.createdAt);
      expect(copy.updatedAt, base.updatedAt);
    });

    test('overrides specified fields', () {
      final copy = base.copyWith(
        text: 'Updated text',
        sourceType: VocabularySourceType.audio,
        sourceId: 'aud1',
      );
      expect(copy.text, 'Updated text');
      expect(copy.sourceType, VocabularySourceType.audio);
      expect(copy.sourceId, 'aud1');
      expect(copy.id, 'ctx1');
    });

    test('clearExplanation sets explanation to null', () {
      expect(base.explanation, isNotNull);
      final copy = base.copyWith(clearExplanation: true);
      expect(copy.explanation, isNull);
    });

    test('explanation param is ignored when clearExplanation is true', () {
      final copy = base.copyWith(
        explanation: 'new value',
        clearExplanation: true,
      );
      expect(copy.explanation, isNull);
    });
  });
}
