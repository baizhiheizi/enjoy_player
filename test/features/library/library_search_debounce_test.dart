import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/application/library_search_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingEnqueue {
  final List<({SyncEntityType type, String id, SyncAction action})> calls =
      <({SyncEntityType type, String id, SyncAction action})>[];

  Future<void> call(SyncEntityType type, String id, SyncAction action) async {
    calls.add((type: type, id: id, action: action));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('librarySearchProvider debounce', () {
    test('setQuery commits after the debounce window', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('alpha');
      // Inside the debounce window the state is still the previous value.
      expect(container.read(librarySearchProvider), '');

      await Future<void>.delayed(
        kLibrarySearchDebounce + const Duration(milliseconds: 50),
      );
      expect(container.read(librarySearchProvider), 'alpha');
    });

    test('rapid setQuery calls only commit the last value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('a');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('ab');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      notifier.setQuery('abc');

      // Still inside the final debounce window.
      expect(container.read(librarySearchProvider), '');

      await Future<void>.delayed(
        kLibrarySearchDebounce + const Duration(milliseconds: 50),
      );
      expect(container.read(librarySearchProvider), 'abc');
    });

    test('commit() flushes the pending value immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('hello');
      notifier.commit();

      // No wait — the value is committed right away.
      expect(container.read(librarySearchProvider), 'hello');
    });

    test('setQuery trims whitespace', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(librarySearchProvider.notifier);

      notifier.setQuery('  hello world  ');
      notifier.commit();
      expect(container.read(librarySearchProvider), 'hello world');
    });
  });

  group('MediaLibraryRepository.deleteMedia atomicity', () {
    test('sync enqueue and local delete are in one transaction', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final enqueue = _RecordingEnqueue();
      final repo = MediaLibraryRepository(
        db,
        FileStorage(),
        enqueueSync: enqueue.call,
      );

      final id = 'v1';
      await db.videoDao.insertRow(_videoRow(id, 'V1', 'hash-1'));
      await repo.deleteMedia(id);

      // Sync enqueue was called for the video delete.
      expect(enqueue.calls, hasLength(1));
      expect(enqueue.calls.single.type, SyncEntityType.video);
      expect(enqueue.calls.single.action, SyncAction.delete);

      // Local row is gone.
      expect(await db.videoDao.getById(id), isNull);
    });

    test('failed sync enqueue rolls back the local delete', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);

      Future<void> throwingEnqueue(
        SyncEntityType type,
        String id,
        SyncAction action,
      ) async {
        throw StateError('enqueue offline');
      }

      final repo = MediaLibraryRepository(
        db,
        FileStorage(),
        enqueueSync: throwingEnqueue,
      );
      final id = 'a1';
      await db.audioDao.insertRow(_audioRow(id, 'A1', 'hash-a'));

      await expectLater(repo.deleteMedia(id), throwsA(isA<StateError>()));

      // The local row must still exist because the enqueue failed and
      // the transaction rolled back.
      expect(await db.audioDao.getById(id), isNotNull);
    });

    test('delete on an unknown id is a no-op', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final enqueue = _RecordingEnqueue();
      final repo = MediaLibraryRepository(
        db,
        FileStorage(),
        enqueueSync: enqueue.call,
      );
      await repo.deleteMedia('does-not-exist');
      expect(enqueue.calls, isEmpty);
    });
  });
}

VideoRow _videoRow(String id, String title, String md5) => VideoRow(
  id: id,
  vid: md5,
  provider: 'user',
  title: title,
  description: null,
  thumbnailUrl: null,
  durationSeconds: 0,
  language: 'und',
  source: null,
  localUri: 'file:///x.mp4',
  md5: md5,
  size: 0,
  mediaUrl: null,
  syncStatus: null,
  serverUpdatedAt: null,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

AudioRow _audioRow(String id, String title, String md5) => AudioRow(
  id: id,
  aid: md5,
  provider: 'user',
  title: title,
  description: null,
  thumbnailUrl: null,
  durationSeconds: 0,
  language: 'und',
  translationKey: null,
  sourceText: null,
  voice: null,
  source: null,
  localUri: 'file:///x.mp3',
  md5: md5,
  size: 0,
  mediaUrl: null,
  syncStatus: null,
  serverUpdatedAt: null,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
