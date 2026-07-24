import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/craft/application/craft_history_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the first emitted value of a [StreamProvider] by keeping a
/// listener alive for the duration of the read. `container.read(...future)`
/// alone does not retain a subscription long enough for a cold
/// (non-broadcast) stream to emit before the provider is torn down.
Future<List<Media>> _firstValue(
  ProviderContainer container,
  StreamProvider<List<Media>> provider,
) async {
  final completer = Completer<List<Media>>();
  final sub = container.listen(provider, (_, next) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
    } else if (next.hasError && !completer.isCompleted) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    sub.close();
  }
}

class _FakeLibraryRepository extends MediaLibraryRepository {
  _FakeLibraryRepository(super.db, super.storage, this._items);

  final List<Media> _items;

  @override
  Stream<List<Media>> watchAll() => Stream.value(_items);
}

Media _media({
  required String id,
  required String provider,
  required DateTime updatedAt,
}) {
  return Media(
    id: id,
    kind: MediaKind.audio,
    title: 'Item $id',
    sourceUri: 'file:///$id.wav',
    durationMs: 1000,
    language: 'en-US',
    contentHash: id,
    fileSize: 10,
    provider: provider,
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('filters to provider = craft and sorts newest-updated first', () async {
    final now = DateTime.now();
    final items = [
      _media(id: 'user-1', provider: 'user', updatedAt: now),
      _media(
        id: 'craft-old',
        provider: 'craft',
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      _media(id: 'youtube-1', provider: 'youtube', updatedAt: now),
      _media(
        id: 'craft-new',
        provider: 'craft',
        updatedAt: now.add(const Duration(minutes: 5)),
      ),
    ];
    final repo = _FakeLibraryRepository(db, FileStorage(), items);

    final container = ProviderContainer(
      overrides: [mediaLibraryRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result = await _firstValue(container, craftHistoryProvider);

    expect(result.map((m) => m.id).toList(), ['craft-new', 'craft-old']);
  });

  test('emits an empty list when there are no craft items', () async {
    final repo = _FakeLibraryRepository(db, FileStorage(), [
      _media(id: 'user-1', provider: 'user', updatedAt: DateTime.now()),
    ]);

    final container = ProviderContainer(
      overrides: [mediaLibraryRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result = await _firstValue(container, craftHistoryProvider);
    expect(result, isEmpty);
  });
}
