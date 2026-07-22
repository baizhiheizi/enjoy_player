import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_csv.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_export_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_locator_json.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_srs.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem _item({
  required String id,
  String word = 'test',
  VocabularyStatus status = VocabularyStatus.new_,
  DateTime? nextReviewAt,
  DateTime? lastReviewedAt,
  String language = 'en',
  String targetLanguage = 'zh',
  String? explanation,
  int reviewsCount = 0,
  int interval = 0,
  double easeFactor = kDefaultEaseFactor,
}) {
  final created = DateTime.utc(2024, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: language,
    targetLanguage: targetLanguage,
    status: status,
    easeFactor: easeFactor,
    interval: interval,
    nextReviewAt: nextReviewAt ?? DateTime.utc(2024, 6, 15, 12),
    reviewsCount: reviewsCount,
    lastReviewedAt: lastReviewedAt,
    contextsCount: 0,
    explanation: explanation,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  group('stableEbookLocatorJson', () {
    test('produces sorted top-level keys', () {
      const locator = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'application/xhtml+xml',
        title: 'Chapter 1',
      );
      final json = stableEbookLocatorJson(locator);
      final hrefIdx = json.indexOf('"href"');
      final locatorTypeIdx = json.indexOf('"locatorType"');
      final titleIdx = json.indexOf('"title"');
      final typeIdx = json.indexOf('"type"');
      expect(hrefIdx, lessThan(locatorTypeIdx));
      expect(locatorTypeIdx, lessThan(titleIdx));
      expect(titleIdx, lessThan(typeIdx));
    });

    test('is deterministic for same locator', () {
      const a = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'application/xhtml+xml',
      );
      const b = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'application/xhtml+xml',
      );
      expect(stableEbookLocatorJson(a), stableEbookLocatorJson(b));
    });

    test('changes when fields differ', () {
      const a = EbookLocator(
        href: 'ch01.xhtml',
        locatorType: 'application/xhtml+xml',
      );
      const b = EbookLocator(
        href: 'ch02.xhtml',
        locatorType: 'application/xhtml+xml',
      );
      expect(stableEbookLocatorJson(a), isNot(stableEbookLocatorJson(b)));
    });
  });

  group('encodeLocatorForDb error paths', () {
    test('throws when neither media nor ebook provided', () {
      expect(() => encodeLocatorForDb(), throwsArgumentError);
    });
  });

  group('decodeLocatorFromDb error paths', () {
    test('throws FormatException on unknown type', () {
      expect(
        () => decodeLocatorFromDb('{"type":"unknown","start":0}'),
        throwsFormatException,
      );
    });
  });

  group('markdownToHtmlSimple', () {
    test('returns empty string for blank input', () {
      expect(markdownToHtmlSimple(''), '');
      expect(markdownToHtmlSimple('   '), '');
    });

    test('converts h1 headings', () {
      expect(markdownToHtmlSimple('# Title'), '<h1>Title</h1>');
    });

    test('converts h2 headings', () {
      expect(markdownToHtmlSimple('## Subtitle'), '<h2>Subtitle</h2>');
    });

    test('converts h3 headings', () {
      expect(markdownToHtmlSimple('### Section'), '<h3>Section</h3>');
    });

    test('converts bold text', () {
      expect(markdownToHtmlSimple('**bold**'), '<strong>bold</strong>');
    });

    test('converts italic text', () {
      expect(markdownToHtmlSimple('*italic*'), '<em>italic</em>');
    });

    test('converts unordered list items', () {
      final result = markdownToHtmlSimple('- item one\n- item two');
      expect(result, contains('<li>item one</li>'));
      expect(result, contains('<li>item two</li>'));
      expect(result, contains('<ul>'));
    });

    test('converts asterisk list items', () {
      final result = markdownToHtmlSimple('* alpha\n* beta');
      expect(result, contains('<li>alpha</li>'));
      expect(result, contains('<li>beta</li>'));
    });

    test('converts inline code', () {
      expect(
        markdownToHtmlSimple('use `foo` here'),
        contains('<code>foo</code>'),
      );
    });

    test('converts code blocks', () {
      final result = markdownToHtmlSimple('```\ncode here\n```');
      expect(result, contains('code here'));
      expect(result, contains('<code>'));
    });

    test('converts double-space newline to br', () {
      expect(markdownToHtmlSimple('line1  \nline2'), contains('<br>'));
    });

    test('converts double newline to double br', () {
      expect(markdownToHtmlSimple('para1\n\npara2'), contains('<br><br>'));
    });

    test('converts single newline to br', () {
      final result = markdownToHtmlSimple('a\nb');
      expect(result, contains('<br>'));
    });

    test('handles mixed markdown', () {
      const md = '# Title\n\n**Bold** and *italic*\n\n- item';
      final result = markdownToHtmlSimple(md);
      expect(result, contains('<h1>Title</h1>'));
      expect(result, contains('<strong>Bold</strong>'));
      expect(result, contains('<em>italic</em>'));
      expect(result, contains('<li>item</li>'));
    });
  });

  group('exportVocabularyToAnkiCsv — source references', () {
    test('includes source reference when provided', () {
      final item = _item(id: 'i1', word: 'hello');
      final now = DateTime.utc(2024, 1, 1);
      final ctx = VocabularyContext(
        id: 'c1',
        vocabularyItemId: 'i1',
        text: 'Hello world',
        sourceType: VocabularySourceType.video,
        sourceId: 'vid1',
        locator: const MediaLocator(start: 0, duration: 1000),
        createdAt: now,
        updatedAt: now,
      );
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {
          'i1': [ctx],
        },
        sourceRefs: {
          'Video:vid1': const AnkiSourceReference(
            type: 'Video',
            title: 'My Movie',
          ),
        },
      );
      expect(csv, contains('Source: Video: My Movie'));
    });

    test('omits source line when no refs match', () {
      final item = _item(id: 'i1', word: 'hello');
      final now = DateTime.utc(2024, 1, 1);
      final ctx = VocabularyContext(
        id: 'c1',
        vocabularyItemId: 'i1',
        text: 'Hello world',
        sourceType: VocabularySourceType.video,
        sourceId: 'vid1',
        locator: const MediaLocator(start: 0, duration: 1000),
        createdAt: now,
        updatedAt: now,
      );
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {
          'i1': [ctx],
        },
        sourceRefs: const {},
      );
      expect(csv, isNot(contains('Source:')));
    });
  });

  group('exportVocabularyToAnkiCsv — examples and multiple contexts', () {
    test('includes examples from dictionary senses', () {
      final dictJson =
          '{"word":"run","sourceLanguage":"en","targetLanguage":"zh",'
          '"senses":[{"definition":"to move quickly","translation":"跑",'
          '"partOfSpeech":"verb","examples":['
          '{"source":"I run every day","target":"我每天跑步"},'
          '{"source":"She runs fast"}'
          ']}]}';
      final item = _item(id: 'i1', word: 'run', explanation: dictJson);
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: const {},
      );
      expect(csv, contains('Examples:'));
      expect(csv, contains('I run every day'));
      expect(csv, contains('我每天跑步'));
      expect(csv, contains('She runs fast'));
    });

    test('joins multiple context texts with hr', () {
      final item = _item(id: 'i1', word: 'hello');
      final now = DateTime.utc(2024, 1, 1);
      final contexts = [
        VocabularyContext(
          id: 'c1',
          vocabularyItemId: 'i1',
          text: 'First context',
          sourceType: VocabularySourceType.video,
          sourceId: 'v1',
          locator: const MediaLocator(start: 0, duration: 100),
          createdAt: now,
          updatedAt: now,
        ),
        VocabularyContext(
          id: 'c2',
          vocabularyItemId: 'i1',
          text: 'Second context',
          sourceType: VocabularySourceType.audio,
          sourceId: 'a1',
          locator: const MediaLocator(start: 500, duration: 200),
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {'i1': contexts},
      );
      expect(csv, contains('First context'));
      expect(csv, contains('Second context'));
      expect(csv, contains('<hr>'));
    });
  });

  group('VocabularyAnkiExportFilters.copyWith', () {
    test('overrides query', () {
      const filters = VocabularyAnkiExportFilters(query: 'old');
      final copy = filters.copyWith(query: 'new');
      expect(copy.query, 'new');
    });

    test('overrides status', () {
      const filters = VocabularyAnkiExportFilters();
      final copy = filters.copyWith(status: VocabularyStatus.mastered);
      expect(copy.status, VocabularyStatus.mastered);
    });

    test('clearStatus removes status', () {
      const filters = VocabularyAnkiExportFilters(
        status: VocabularyStatus.learning,
      );
      final copy = filters.copyWith(clearStatus: true);
      expect(copy.status, isNull);
    });

    test('overrides language', () {
      const filters = VocabularyAnkiExportFilters();
      final copy = filters.copyWith(language: 'ja');
      expect(copy.language, 'ja');
    });

    test('clearLanguage removes language', () {
      const filters = VocabularyAnkiExportFilters(language: 'en');
      final copy = filters.copyWith(clearLanguage: true);
      expect(copy.language, isNull);
    });

    test('preserves unset fields', () {
      const filters = VocabularyAnkiExportFilters(
        query: 'hello',
        status: VocabularyStatus.reviewing,
        language: 'fr',
      );
      final copy = filters.copyWith(query: 'world');
      expect(copy.status, VocabularyStatus.reviewing);
      expect(copy.language, 'fr');
    });
  });

  group('filterVocabularyItemsForAnkiExport — additional paths', () {
    test('filters by language', () {
      final items = [
        _item(id: '1', word: 'hello', language: 'en'),
        _item(id: '2', word: 'bonjour', language: 'fr'),
      ];
      final filtered = filterVocabularyItemsForAnkiExport(
        items,
        const VocabularyAnkiExportFilters(language: 'fr'),
      );
      expect(filtered.map((e) => e.id), ['2']);
    });

    test('query matches on language field', () {
      final items = [
        _item(id: '1', word: 'hello', language: 'en'),
        _item(id: '2', word: 'bonjour', language: 'fr'),
      ];
      final filtered = filterVocabularyItemsForAnkiExport(
        items,
        const VocabularyAnkiExportFilters(query: 'fr'),
      );
      expect(filtered.map((e) => e.id), ['2']);
    });

    test('empty query returns all items', () {
      final items = [
        _item(id: '1', word: 'hello'),
        _item(id: '2', word: 'world'),
      ];
      final filtered = filterVocabularyItemsForAnkiExport(
        items,
        const VocabularyAnkiExportFilters(query: ''),
      );
      expect(filtered.length, 2);
    });

    test('whitespace-only query returns all items', () {
      final items = [
        _item(id: '1', word: 'hello'),
        _item(id: '2', word: 'world'),
      ];
      final filtered = filterVocabularyItemsForAnkiExport(
        items,
        const VocabularyAnkiExportFilters(query: '   '),
      );
      expect(filtered.length, 2);
    });

    test('combined status + language + query', () {
      final items = [
        _item(
          id: '1',
          word: 'hello',
          language: 'en',
          status: VocabularyStatus.learning,
        ),
        _item(
          id: '2',
          word: 'help',
          language: 'en',
          status: VocabularyStatus.mastered,
        ),
        _item(
          id: '3',
          word: 'hola',
          language: 'es',
          status: VocabularyStatus.learning,
        ),
      ];
      final filtered = filterVocabularyItemsForAnkiExport(
        items,
        const VocabularyAnkiExportFilters(
          query: 'hel',
          status: VocabularyStatus.learning,
          language: 'en',
        ),
      );
      expect(filtered.map((e) => e.id), ['1']);
    });
  });

  group('calculateNextReview — edge cases', () {
    final now = DateTime.utc(2024, 6, 15, 12, 30);

    test(
      'know with interval 0 but reviewsCount > 0 still gives MIN interval',
      () {
        final result = calculateNextReview(
          easeFactor: 2.5,
          interval: 0,
          reviewsCount: 2,
          status: VocabularyStatus.learning,
          rating: VocabularyRating.know,
          now: now,
        );
        expect(result.interval, kMinIntervalDays);
      },
    );

    test('knowWell interval clamped at max', () {
      final result = calculateNextReview(
        easeFactor: 2.5,
        interval: 300,
        reviewsCount: 10,
        status: VocabularyStatus.reviewing,
        rating: VocabularyRating.knowWell,
        now: now,
      );
      expect(result.interval, kMaxIntervalDays);
    });

    test('dontKnow ease clamped exactly at min', () {
      final result = calculateNextReview(
        easeFactor: kMinEaseFactor,
        interval: 5,
        reviewsCount: 3,
        status: VocabularyStatus.reviewing,
        rating: VocabularyRating.dontKnow,
        now: now,
      );
      expect(result.easeFactor, kMinEaseFactor);
    });

    test('knowWell ease clamped exactly at max', () {
      final result = calculateNextReview(
        easeFactor: kMaxEaseFactor,
        interval: 5,
        reviewsCount: 3,
        status: VocabularyStatus.reviewing,
        rating: VocabularyRating.knowWell,
        now: now,
      );
      expect(result.easeFactor, kMaxEaseFactor);
    });

    test('nextReviewAt uses UTC midnight even for non-UTC now', () {
      final localNow = DateTime(2024, 6, 15, 22, 0);
      final result = calculateNextReview(
        easeFactor: 2.5,
        interval: 0,
        reviewsCount: 0,
        status: VocabularyStatus.new_,
        rating: VocabularyRating.know,
        now: localNow,
      );
      expect(result.nextReviewAt.isUtc, isTrue);
      expect(result.nextReviewAt.hour, 0);
      expect(result.nextReviewAt.minute, 0);
    });

    test('lastReviewedAt equals now', () {
      final result = calculateNextReview(
        easeFactor: 2.5,
        interval: 0,
        reviewsCount: 0,
        status: VocabularyStatus.new_,
        rating: VocabularyRating.know,
        now: now,
      );
      expect(result.lastReviewedAt, now);
    });
  });

  group('isVocabularyItemDue — boundary cases', () {
    test('not due when nextReviewAt equals lastReviewedAt exactly', () {
      final t = DateTime.utc(2024, 6, 10);
      expect(
        isVocabularyItemDue(
          nextReviewAt: t,
          lastReviewedAt: t,
          now: DateTime.utc(2024, 6, 15),
        ),
        isFalse,
      );
    });

    test(
      'due when nextReviewAt is 1ms after lastReviewedAt and before now',
      () {
        final last = DateTime.utc(2024, 6, 10);
        final next = last.add(const Duration(milliseconds: 1));
        expect(
          isVocabularyItemDue(
            nextReviewAt: next,
            lastReviewedAt: last,
            now: DateTime.utc(2024, 6, 15),
          ),
          isTrue,
        );
      },
    );
  });

  group('VocabularyStats equality and toString', () {
    test('equal instances are equal', () {
      const a = VocabularyStats(
        total: 10,
        due: 3,
        newCount: 2,
        learningCount: 3,
        reviewingCount: 3,
        masteredCount: 2,
      );
      const b = VocabularyStats(
        total: 10,
        due: 3,
        newCount: 2,
        learningCount: 3,
        reviewingCount: 3,
        masteredCount: 2,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different instances are not equal', () {
      const a = VocabularyStats(
        total: 10,
        due: 3,
        newCount: 2,
        learningCount: 3,
        reviewingCount: 3,
        masteredCount: 2,
      );
      const b = VocabularyStats(
        total: 11,
        due: 3,
        newCount: 2,
        learningCount: 3,
        reviewingCount: 3,
        masteredCount: 2,
      );
      expect(a, isNot(equals(b)));
    });

    test('toString contains field values', () {
      const stats = VocabularyStats(
        total: 5,
        due: 2,
        newCount: 1,
        learningCount: 2,
        reviewingCount: 1,
        masteredCount: 1,
      );
      final str = stats.toString();
      expect(str, contains('total: 5'));
      expect(str, contains('due: 2'));
      expect(str, contains('new: 1'));
      expect(str, contains('learning: 2'));
      expect(str, contains('reviewing: 1'));
      expect(str, contains('mastered: 1'));
    });
  });
}
