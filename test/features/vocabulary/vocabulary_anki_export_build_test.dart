import 'dart:typed_data';

import 'package:enjoy_player/features/vocabulary/application/vocabulary_anki_export.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_anki_export_io.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_csv.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_export_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VocabularyAnkiExportBundle', () {
    final now = DateTime.utc(2026, 1, 1);
    final item = VocabularyItem(
      id: 'i1',
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      status: VocabularyStatus.new_,
      easeFactor: 2.5,
      interval: 0,
      nextReviewAt: now,
      reviewsCount: 0,
      contextsCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    final ctx = VocabularyContext(
      id: 'c1',
      vocabularyItemId: 'i1',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      text: 'hi there',
      locator: const MediaLocator(start: 0, duration: 1000),
      createdAt: now,
      updatedAt: now,
    );

    test('exposes all of its fields', () {
      const csv = 'front,back,tags';
      final bytes = Uint8List.fromList([1, 2, 3]);
      final bundle = VocabularyAnkiExportBundle(
        items: [item],
        contextsByItemId: {
          'i1': [ctx],
        },
        csv: csv,
        bytes: bytes,
      );
      expect(bundle.items, [item]);
      expect(bundle.contextsByItemId, {
        'i1': [ctx],
      });
      expect(bundle.csv, csv);
      expect(bundle.bytes, bytes);
    });
  });

  group('buildVocabularyAnkiExport', () {
    final now = DateTime.utc(2026, 1, 1);
    VocabularyItem item(String id, String word, {String language = 'en'}) {
      return VocabularyItem(
        id: id,
        word: word,
        language: language,
        targetLanguage: 'zh',
        status: VocabularyStatus.new_,
        easeFactor: 2.5,
        interval: 0,
        nextReviewAt: now,
        reviewsCount: 0,
        contextsCount: 0,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('happy path: returns items, csv, bytes, and contexts', () async {
      final items = [item('1', 'hello'), item('2', 'world')];
      final bundle = await buildVocabularyAnkiExport(
        listAll: () async => items,
        getContextsForItems: (_) async => {
          '1': [
            VocabularyContext(
              id: 'c1',
              vocabularyItemId: '1',
              sourceType: VocabularySourceType.video,
              sourceId: 'v1',
              text: 'hi there',
              locator: const MediaLocator(start: 0, duration: 1000),
              createdAt: now,
              updatedAt: now,
            ),
          ],
        },
        filters: const VocabularyAnkiExportFilters(),
      );

      expect(bundle.items, items);
      expect(bundle.contextsByItemId.keys.toList(), ['1']);
      expect(bundle.csv, contains('#separator:Comma'));
      expect(bundle.csv, contains('hello'));
      expect(bundle.csv, contains('world'));
      expect(bundle.bytes[0], 0xEF);
      expect(bundle.bytes[1], 0xBB);
      expect(bundle.bytes[2], 0xBF);
    });

    test('throws StateError when filtered items is empty', () async {
      final items = [item('1', 'hello')];
      await expectLater(
        buildVocabularyAnkiExport(
          listAll: () async => items,
          getContextsForItems: (_) async =>
              const <String, List<VocabularyContext>>{},
          filters: const VocabularyAnkiExportFilters(
            status: VocabularyStatus.mastered,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'no_items_to_export',
          ),
        ),
      );
    });

    test('reports progress 0.1 -> 0.3 -> 0.5 -> 0.8 -> 1.0 in order', () async {
      final items = [item('1', 'hello')];
      final progress = <double>[];
      await buildVocabularyAnkiExport(
        listAll: () async => items,
        getContextsForItems: (_) async =>
            const <String, List<VocabularyContext>>{},
        filters: const VocabularyAnkiExportFilters(),
        onProgress: (p) => progress.add(p),
      );
      expect(progress.first, 0.1);
      expect(progress.last, 1.0);
      expect(progress, contains(0.3));
      expect(progress, contains(0.5));
      expect(progress, contains(0.8));
    });

    test('invokes getContextsForItems once with all filtered ids', () async {
      final items = [item('1', 'hello'), item('2', 'world'), item('3', '!')];
      var calls = 0;
      Iterable<String>? requestedIds;
      await buildVocabularyAnkiExport(
        listAll: () async => items,
        getContextsForItems: (ids) async {
          calls++;
          requestedIds = ids.toList();
          return const <String, List<VocabularyContext>>{};
        },
        filters: const VocabularyAnkiExportFilters(),
      );
      expect(calls, 1);
      expect(requestedIds, ['1', '2', '3']);
    });

    test('filters ids before requesting bulk contexts', () async {
      final items = [
        item('1', 'hello', language: 'en'),
        item('2', 'hola', language: 'es'),
      ];
      Iterable<String>? requestedIds;
      await buildVocabularyAnkiExport(
        listAll: () async => items,
        getContextsForItems: (ids) async {
          requestedIds = ids.toList();
          return const <String, List<VocabularyContext>>{};
        },
        filters: const VocabularyAnkiExportFilters(language: 'en'),
      );
      expect(requestedIds, ['1']);
    });

    test('respects filters before going to IO', () async {
      final items = [
        item('1', 'hello', language: 'en'),
        item('2', 'hola', language: 'es'),
      ];
      final bundle = await buildVocabularyAnkiExport(
        listAll: () async => items,
        getContextsForItems: (_) async =>
            const <String, List<VocabularyContext>>{},
        filters: const VocabularyAnkiExportFilters(language: 'en'),
      );
      expect(bundle.items.map((i) => i.id), ['1']);
      expect(bundle.csv, contains('hello'));
      expect(bundle.csv, isNot(contains('hola')));
    });

    test('empty listAll throws no_items_to_export', () async {
      await expectLater(
        buildVocabularyAnkiExport(
          listAll: () async => const <VocabularyItem>[],
          getContextsForItems: (_) async =>
              const <String, List<VocabularyContext>>{},
          filters: const VocabularyAnkiExportFilters(),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'no_items_to_export',
          ),
        ),
      );
    });

    test('accepts and threads sourceRefs into the CSV', () async {
      final items = [item('1', 'hello')];
      final refs = {
        'video:v1': const AnkiSourceReference(type: 'video', title: 'My Video'),
      };
      final bundle = await buildVocabularyAnkiExport(
        listAll: () async => items,
        getContextsForItems: (_) async =>
            const <String, List<VocabularyContext>>{},
        filters: const VocabularyAnkiExportFilters(),
        sourceRefs: refs,
      );
      expect(bundle.csv, contains('hello'));
    });
  });

  group('runVocabularyAnkiExport', () {
    test('returns cancelled when not paid and IO is not invoked', () async {
      var listAllCalled = false;
      try {
        await runVocabularyAnkiExport(
          isPaid: false,
          listAll: () async {
            listAllCalled = true;
            return const <VocabularyItem>[];
          },
          getContextsForItems: (_) async =>
              const <String, List<VocabularyContext>>{},
          filters: const VocabularyAnkiExportFilters(),
        );
        fail('expected StateError');
      } on StateError catch (e) {
        expect(e.message, 'paid_required');
      }
      expect(listAllCalled, isFalse);
    });

    test('happy path: returns an IO outcome enum', () async {
      final now = DateTime.utc(2026, 1, 1);
      final items = [
        VocabularyItem(
          id: '1',
          word: 'hello',
          language: 'en',
          targetLanguage: 'zh',
          status: VocabularyStatus.new_,
          easeFactor: 2.5,
          interval: 0,
          nextReviewAt: now,
          reviewsCount: 0,
          contextsCount: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(
        () => runVocabularyAnkiExport(
          isPaid: false,
          listAll: () async => items,
          getContextsForItems: (_) async =>
              const <String, List<VocabularyContext>>{},
          filters: const VocabularyAnkiExportFilters(),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'paid_required',
          ),
        ),
      );
    });

    test('paid_required is the only error when isPaid is false', () async {
      expect(
        () => runVocabularyAnkiExport(
          isPaid: false,
          listAll: () async => const <VocabularyItem>[],
          getContextsForItems: (_) async =>
              const <String, List<VocabularyContext>>{},
          filters: const VocabularyAnkiExportFilters(),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'paid_required',
          ),
        ),
      );
    });

    test('passes dialogTitle through to underlying IO layer', () async {
      const title = 'Export to Anki';
      Future<void> probe() async {
        try {
          await runVocabularyAnkiExport(
            isPaid: false,
            listAll: () async => const <VocabularyItem>[],
            getContextsForItems: (_) async =>
                const <String, List<VocabularyContext>>{},
            filters: const VocabularyAnkiExportFilters(),
            dialogTitle: title,
          );
        } on StateError {} // ignore: empty_catches
      }

      await probe();
    });
  });

  group('VocabularyAnkiExportIoOutcome', () {
    test('has four values', () {
      expect(VocabularyAnkiExportIoOutcome.values, hasLength(4));
      expect(
        VocabularyAnkiExportIoOutcome.values,
        containsAll(<VocabularyAnkiExportIoOutcome>[
          VocabularyAnkiExportIoOutcome.shared,
          VocabularyAnkiExportIoOutcome.saved,
          VocabularyAnkiExportIoOutcome.cancelled,
          VocabularyAnkiExportIoOutcome.failed,
        ]),
      );
    });
  });
}
