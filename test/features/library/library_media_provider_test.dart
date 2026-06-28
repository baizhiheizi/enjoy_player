import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/application/library_search_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

typedef _FilteredLists = ({List<Media> audio, List<Media> video});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('library provider dedupe', () {
    late AppDatabase db;
    late Directory root;
    late MediaLibraryRepository repo;

    setUp(() async {
      root = Directory.systemTemp.createTempSync('enjoy_lib_media_prov_test');
      PathProviderPlatform.instance = TestPathProvider(root.path);
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = MediaLibraryRepository(db, FileStorage());
      // Seed two audio + one video so the lists are non-trivial.
      await db.audioDao.insertRow(
        _audio('a-old', 'Alpha', 'old', DateTime(2026, 1, 1)),
      );
      await db.audioDao.insertRow(
        _audio('b-new', 'Bravo', 'new', DateTime(2026, 6, 1)),
      );
      await db.videoDao.insertRow(
        _video('v-mid', 'Charlie', 'mid', DateTime(2026, 3, 1)),
      );
    });

    tearDown(() async {
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          mediaLibraryRepositoryProvider.overrideWithValue(repo),
          syncEnqueueProvider.overrideWithValue((_, _, _) async {}),
        ],
      );
    }

    test(
      'libraryHomeRecentsProvider skips identical re-emissions',
      skip:
          'Provider-level dedupe is covered by stream_distinct_test; '
          'Drift upsert makes a no-op DB touch hard to simulate here.',
      () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final emissions = <int>[];
      final sub = container.listen(libraryHomeRecentsProvider, (_, next) {
        if (next.hasValue) emissions.add(next.requireValue.length);
      }, fireImmediately: true);
      // Wait for the initial emission (seeded data).
      await container.read(libraryHomeRecentsProvider.future);
      emissions.clear();

      // Force watchAll to re-query without changing mapped [Media] values.
      // syncStatus is not surfaced on [Media]; preserve updatedAt so the
      // top-12 ordering and element equality stay the same.
      await _touchSyncStatusOnly(db, 'a-old');
      // Yield enough times for the StreamProvider to flush.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        emissions,
        isEmpty,
        reason:
            'Identical top-12 should not re-emit. '
            'Got $emissions emissions after a no-op write.',
      );

      // Real change to the top-12 (a brand-new most-recent item) MUST emit.
      await db.videoDao.insertRow(
        _video('v-newest', 'Delta', 'newest', DateTime(2026, 12, 1)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        emissions,
        isNotEmpty,
        reason:
            'A real top-12 change (newest item) must re-emit. '
            'Got $emissions emissions.',
      );

      sub.close();
    });

    test(
      'libraryFilteredListsProvider skips identical re-emissions '
      'and re-emits on real changes',
      skip:
          'Provider-level dedupe is covered by stream_distinct_test; '
          'Drift upsert makes a no-op DB touch hard to simulate here.',
      () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final emissions = <String>[];
      final sub = container.listen(libraryFilteredListsProvider, (prev, next) {
        if (!next.hasValue) return;
        final sig = _signature(next.requireValue);
        if (emissions.isNotEmpty && emissions.last == sig) return;
        emissions.add(sig);
      }, fireImmediately: true);
      await container.read(libraryFilteredListsProvider.future);
      emissions.clear();

      await _touchSyncStatusOnly(db, 'a-old');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions, isEmpty, reason: 'No-op write should be deduped.');

      // Real change: rename Alpha → Zebra. Now audio list is
      // [Bravo, Zebra], which differs, so we must see an emission.
      final renamedRow = await db.audioDao.getById('a-old');
      await db.audioDao.insertRow(renamedRow!.copyWith(title: 'Zebra'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        emissions,
        isNotEmpty,
        reason:
            'A real filter-list change (renamed audio) must re-emit. '
            'Got $emissions emissions.',
      );

      sub.close();
    });

    test(
      'libraryFilteredListsProvider re-emits when search query changes',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        final emissions = <int>[];
        final sub = container.listen(libraryFilteredListsProvider, (
          prev,
          next,
        ) {
          if (next.hasValue) {
            emissions.add(
              next.requireValue.audio.length + next.requireValue.video.length,
            );
          }
        }, fireImmediately: true);
        await container.read(libraryFilteredListsProvider.future);
        emissions.clear();

        container.read(librarySearchProvider.notifier).setQuery('zz');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // Empty result set is a real change; should emit.
        expect(emissions, isNotEmpty);
        expect(emissions.last, 0);

        sub.close();
      },
    );
  });
}

Future<void> _touchSyncStatusOnly(AppDatabase db, String id) async {
  final row = await db.audioDao.getById(id);
  await db.audioDao.insertRow(
    row!.copyWith(
      syncStatus: const Value('pending'),
      updatedAt: row.updatedAt,
      createdAt: row.createdAt,
    ),
  );
}

String _signature(_FilteredLists v) {
  return '${v.audio.map((m) => m.id).join(',')}|'
      '${v.video.map((m) => m.id).join(',')}';
}

AudioRow _audio(String id, String title, String aid, DateTime when) {
  return AudioRow(
    id: id,
    aid: aid,
    provider: 'user',
    title: title,
    description: null,
    thumbnailUrl: null,
    durationSeconds: 10,
    language: 'und',
    translationKey: null,
    sourceText: null,
    voice: null,
    source: null,
    localUri: 'file:///$aid.mp3',
    md5: null,
    size: 1,
    mediaUrl: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: when,
    updatedAt: when,
  );
}

VideoRow _video(String id, String title, String vid, DateTime when) {
  return VideoRow(
    id: id,
    vid: vid,
    provider: 'user',
    title: title,
    description: null,
    thumbnailUrl: null,
    durationSeconds: 10,
    language: 'und',
    source: null,
    localUri: 'file:///$vid.mp4',
    md5: null,
    size: 1,
    mediaUrl: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: when,
    updatedAt: when,
  );
}
