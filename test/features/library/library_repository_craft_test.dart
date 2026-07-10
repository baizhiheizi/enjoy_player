import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

const _testUserId = 'test-user';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaLibraryRepository.importCraftedFromText', () {
    late PathProviderPlatform original;
    late Directory root;
    late AppDatabase db;
    late MediaLibraryRepository repo;

    setUp(() {
      original = PathProviderPlatform.instance;
      root = Directory.systemTemp.createTempSync('enjoy_craft_repo_test');
      PathProviderPlatform.instance = TestPathProvider(root.path);
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = MediaLibraryRepository(db, FileStorage());
    });

    tearDown(() async {
      PathProviderPlatform.instance = original;
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('Speak directly writes audio row + primary transcript', () async {
      final audioBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final id = await repo.importCraftedFromText(
        audioBytes: audioBytes,
        audioFormat: 'wav',
        learningLanguage: 'en',
        sourceLanguage: null,
        text: 'Hello, this is a test sentence for synthesis.',
        normalizedText: 'Hello, this is a test sentence for synthesis.',
        sourceFlag: 'craft-direct',
        signedInUserId: _testUserId,
      );

      // Audio row exists with provider = craft.
      final audioRow = await db.audioDao.getById(id);
      expect(audioRow, isNotNull);
      expect(audioRow!.provider, 'craft');
      expect(audioRow.source, 'craft-direct');
      expect(audioRow.language, 'en-US');
      expect(
        audioRow.sourceText,
        'Hello, this is a test sentence for synthesis.',
      );

      // Primary transcript exists.
      final transcripts = await db.transcriptDao.listForTarget('Audio', id);
      expect(transcripts, hasLength(1));
      expect(transcripts.first.source, 'ai');
      expect(transcripts.first.language.startsWith('en'), isTrue);
    });

    test(
      'Translate then speak writes only the learning-language transcript',
      () async {
        final audioBytes = Uint8List.fromList([10, 20, 30]);

        final id = await repo.importCraftedFromText(
          audioBytes: audioBytes,
          audioFormat: 'wav',
          learningLanguage: 'zh',
          sourceLanguage: 'en',
          text: 'Hello world this is a test.',
          normalizedText: 'Hello world this is a test.',
          sourceFlag: 'craft-translate',
          signedInUserId: _testUserId,
        );

        // Only one transcript: the learning-language (zh) target.
        // The source-language text is stored on the audio row's sourceText
        // column but is NOT written as a separate transcript (we don't have
        // real word-level alignment between source and target).
        final transcripts = await db.transcriptDao.listForTarget('Audio', id);
        expect(transcripts, hasLength(1));
        expect(transcripts.first.language.startsWith('zh'), isTrue);

        // The audio row still carries the source text for reference.
        final audioRow = await db.audioDao.getById(id);
        expect(audioRow!.sourceText, 'Hello world this is a test.');
      },
    );

    test('dedupes on same content hash', () async {
      final audioBytes = Uint8List.fromList([1, 2, 3]);

      final id1 = await repo.importCraftedFromText(
        audioBytes: audioBytes,
        audioFormat: 'wav',
        learningLanguage: 'en',
        sourceLanguage: null,
        text: 'Same text for dedupe test.',
        normalizedText: 'Same text for dedupe test.',
        sourceFlag: 'craft-direct',
        signedInUserId: _testUserId,
      );

      final id2 = await repo.importCraftedFromText(
        audioBytes: audioBytes,
        audioFormat: 'wav',
        learningLanguage: 'en',
        sourceLanguage: null,
        text: 'Same text for dedupe test.',
        normalizedText: 'Same text for dedupe test.',
        sourceFlag: 'craft-direct',
        signedInUserId: _testUserId,
      );

      expect(id1, id2);
    });

    test('findExistingCrafted returns null for new content', () async {
      final existing = await repo.findExistingCrafted(
        learningLanguage: 'en',
        normalizedText: 'Brand new content never seen.',
        sourceFlag: 'craft-direct',
      );
      expect(existing, isNull);
    });

    test('findExistingCrafted returns id after import', () async {
      await repo.importCraftedFromText(
        audioBytes: Uint8List.fromList([1]),
        audioFormat: 'wav',
        learningLanguage: 'en',
        sourceLanguage: null,
        text: 'Existing crafted content.',
        normalizedText: 'Existing crafted content.',
        sourceFlag: 'craft-direct',
        signedInUserId: _testUserId,
      );

      final existing = await repo.findExistingCrafted(
        learningLanguage: 'en',
        normalizedText: 'Existing crafted content.',
        sourceFlag: 'craft-direct',
      );
      expect(existing, isNotNull);
    });

    test('audio file is written to storage', () async {
      final audioBytes = Uint8List.fromList([100, 101, 102, 103]);

      final id = await repo.importCraftedFromText(
        audioBytes: audioBytes,
        audioFormat: 'wav',
        learningLanguage: 'en',
        sourceLanguage: null,
        text: 'Check file write path.',
        normalizedText: 'Check file write path.',
        sourceFlag: 'craft-direct',
        signedInUserId: _testUserId,
      );

      final audioRow = await db.audioDao.getById(id);
      expect(audioRow, isNotNull);
      expect(audioRow!.localUri, isNotNull);
      expect(audioRow.localUri!.startsWith('file://'), isTrue);

      // File exists on disk.
      final fileUri = Uri.parse(audioRow.localUri!);
      final file = File.fromUri(fileUri);
      expect(await file.exists(), isTrue);
      expect(await file.length(), audioBytes.length);
    });

    test('title is truncated to ~40 chars', () async {
      final longText = 'A' * 100;
      await repo.importCraftedFromText(
        audioBytes: Uint8List.fromList([1]),
        audioFormat: 'wav',
        learningLanguage: 'en',
        sourceLanguage: null,
        text: longText,
        normalizedText: longText,
        sourceFlag: 'craft-direct',
        signedInUserId: _testUserId,
      );

      final rows = await db.audioDao.watchAll().first;
      expect(rows, hasLength(1));
      expect(rows.first.title.length, lessThanOrEqualTo(41)); // 40 + ellipsis
      expect(rows.first.title.endsWith('…'), isTrue);
    });
  });
}
