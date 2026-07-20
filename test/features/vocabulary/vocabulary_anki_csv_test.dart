import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_csv.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_export_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

VocabularyItem _item({
  required String id,
  required String word,
  VocabularyStatus status = VocabularyStatus.new_,
  String? explanation,
  String language = 'en',
  String targetLanguage = 'zh',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: language,
    targetLanguage: targetLanguage,
    status: status,
    easeFactor: 2.5,
    interval: 0,
    nextReviewAt: now,
    reviewsCount: 0,
    contextsCount: 1,
    explanation: explanation,
    createdAt: now,
    updatedAt: now,
  );
}

VocabularyContext _ctx({
  required String id,
  required String itemId,
  required String text,
  String? explanation,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return VocabularyContext(
    id: id,
    vocabularyItemId: itemId,
    text: text,
    sourceType: VocabularySourceType.video,
    sourceId: 'vid1',
    locator: const MediaLocator(start: 0, duration: 1000),
    explanation: explanation,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('exportVocabularyToAnkiCsv', () {
    test('includes BOM-ready header metadata and columns', () {
      final item = _item(id: 'i1', word: 'hello');
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {
          'i1': [_ctx(id: 'c1', itemId: 'i1', text: 'Hello world')],
        },
      );
      expect(csv, contains('#columns:Front,Back,Tags'));
      expect(csv, contains('#notetype:Basic'));
      expect(csv, contains('hello'));
      expect(csv, contains('Hello world'));
      expect(csv, contains('vocabulary en-zh'));
    });

    test('tags include status when not new', () {
      final item = _item(
        id: 'i1',
        word: 'hello',
        status: VocabularyStatus.learning,
      );
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: const {},
      );
      expect(csv, contains('vocabulary en-zh learning'));
    });

    test('escapes commas and quotes in fields', () {
      final item = _item(id: 'i1', word: 'a,b');
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {
          'i1': [_ctx(id: 'c1', itemId: 'i1', text: 'say "hi"')],
        },
      );
      expect(csv, contains('"'));
      expect(csv, contains('""'));
    });

    test('sparse cache omits missing back sections', () {
      final item = _item(id: 'i1', word: 'hello');
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {
          'i1': [_ctx(id: 'c1', itemId: 'i1', text: 'Hi')],
        },
      );
      expect(csv, isNot(contains('Definition:')));
      expect(csv, isNot(contains('Context Translation:')));
    });

    test('includes dictionary and contextual translation when present', () {
      final dict = encodeDictionaryExplanation(
        const DictionaryResult(
          word: 'hello',
          sourceLanguage: 'en',
          targetLanguage: 'zh',
          ipa: 'həˈloʊ',
          senses: [
            DictionarySense(
              definition: 'a greeting',
              translation: '你好',
              partOfSpeech: 'noun',
            ),
          ],
        ),
      );
      final ctxExpl = encodeContextualExplanation(
        const ContextualTranslationResult(translatedText: '你好世界'),
      );
      final item = _item(id: 'i1', word: 'hello', explanation: dict);
      final csv = exportVocabularyToAnkiCsv(
        items: [item],
        contextsByItemId: {
          'i1': [
            _ctx(
              id: 'c1',
              itemId: 'i1',
              text: 'Hello world',
              explanation: ctxExpl,
            ),
          ],
        },
      );
      expect(csv, contains('həˈloʊ'));
      expect(csv, contains('你好'));
      expect(csv, contains('Definition:'));
      expect(csv, contains('Context Translation:'));
      expect(csv, contains('你好世界'));
    });

    test('ankiCsvWithBomBytes starts with UTF-8 BOM', () {
      final bytes = ankiCsvWithBomBytes('a,b,c');
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.sublist(3)), 'a,b,c');
    });
  });

  group('filterVocabularyItemsForAnkiExport', () {
    test('filters by status language and search', () {
      final items = [
        _item(id: '1', word: 'hello', status: VocabularyStatus.learning),
        _item(
          id: '2',
          word: 'bonjour',
          language: 'fr',
          status: VocabularyStatus.new_,
        ),
      ];
      final filtered = filterVocabularyItemsForAnkiExport(
        items,
        const VocabularyAnkiExportFilters(
          query: 'hel',
          status: VocabularyStatus.learning,
        ),
      );
      expect(filtered.map((e) => e.id), ['1']);
    });
  });
}
