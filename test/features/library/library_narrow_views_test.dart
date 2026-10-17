import 'package:drift/native.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_history_provider.dart';
import 'package:enjoy_player/features/library/application/continue_practice_provider.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AudioRow _audio({
  required String id,
  String provider = 'user',
  required DateTime updatedAt,
}) {
  return AudioRow(
    id: id,
    aid: 'aid-$id',
    provider: provider,
    title: 'Audio $id',
    durationSeconds: 0,
    language: 'und',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
  );
}

VideoRow _video({required String id, required DateTime updatedAt}) {
  return VideoRow(
    id: id,
    vid: 'vid-$id',
    provider: 'user',
    title: 'Video $id',
    durationSeconds: 0,
    language: 'und',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
  );
}

EchoSessionRow _session({required String targetId}) {
  final now = DateTime.utc(2026, 10, 17);
  return EchoSessionRow(
    id: 'session-1',
    targetType: 'Audio',
    targetId: targetId,
    language: 'und',
    currentTimeMs: 0,
    playbackRate: 1,
    volume: 1,
    echoStartMs: null,
    echoEndMs: null,
    transcriptId: null,
    secondaryTranscriptId: null,
    recordingsCount: 0,
    recordingsDurationMs: 0,
    lastRecordingAt: null,
    currentSegmentIndex: -1,
    echoActive: false,
    echoStartLine: -1,
    echoEndLine: -1,
    blurActive: false,
    startedAt: now,
    lastActiveAt: now,
    completedAt: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _TrackingRegistry extends MediaRegistry {
  _TrackingRegistry(super.db);

  int watchAllCalls = 0;
  int watchKindCountsCalls = 0;
  final watchByKindCalls = <MediaKind>[];
  final watchByProviderCalls = <String>[];
  final watchByIdsCalls = <Set<String>>[];

  @override
  Stream<List<Media>> watchAll() {
    watchAllCalls++;
    return super.watchAll();
  }

  @override
  Stream<({int audio, int video})> watchKindCounts() {
    watchKindCountsCalls++;
    return super.watchKindCounts();
  }

  @override
  Stream<List<Media>> watchByKind(MediaKind kind) {
    watchByKindCalls.add(kind);
    return super.watchByKind(kind);
  }

  @override
  Stream<List<Media>> watchByProvider(String provider) {
    watchByProviderCalls.add(provider);
    return super.watchByProvider(provider);
  }

  @override
  Stream<List<Media>> watchByIds(Set<String> ids) {
    watchByIdsCalls.add(ids);
    return super.watchByIds(ids);
  }
}

Future<void> _pumpUntil(bool Function() ready) async {
  for (var i = 0; i < 100; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('condition not met within 1 s');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _TrackingRegistry registry;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    registry = _TrackingRegistry(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        mediaRegistryProvider.overrideWithValue(registry),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('library lists read per-kind views, never the whole catalog', () async {
    await db.videoDao.insertRow(
      _video(id: 'v-old', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    await db.videoDao.insertRow(
      _video(id: 'v-new', updatedAt: DateTime.utc(2026, 6, 1)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'a-1', updatedAt: DateTime.utc(2026, 3, 1)),
    );

    final sub = container.listen(
      libraryFilteredListsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await _pumpUntil(() {
      final lists = container.read(libraryFilteredListsProvider).valueOrNull;
      return lists != null &&
          lists.audio.length == 1 &&
          lists.video.length == 2;
    });

    final lists = container.read(libraryFilteredListsProvider).requireValue;
    expect(lists.video.map((m) => m.id).toList(), ['v-new', 'v-old']);
    expect(lists.audio.map((m) => m.id).toList(), ['a-1']);
    expect(registry.watchAllCalls, 0);
    expect(registry.watchByKindCalls.toSet(), {
      MediaKind.audio,
      MediaKind.video,
    });
  });

  test('kind counts use COUNT views, never the whole catalog', () async {
    await db.videoDao.insertRow(
      _video(id: 'v1', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'a1', updatedAt: DateTime.utc(2026, 1, 2)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'a2', updatedAt: DateTime.utc(2026, 1, 3)),
    );

    final sub = container.listen(
      libraryKindCountsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await _pumpUntil(() {
      final counts = container.read(libraryKindCountsProvider).valueOrNull;
      return counts != null && counts.video == 1 && counts.audio == 2;
    });

    expect(registry.watchKindCountsCalls, greaterThanOrEqualTo(1));
    expect(registry.watchAllCalls, 0);
  });

  test(
    'continue practice resolves target ids, never the whole catalog',
    () async {
      await db.audioDao.insertRow(
        _audio(id: 'practiced', updatedAt: DateTime.utc(2026, 1, 1)),
      );
      await db.audioDao.insertRow(
        _audio(id: 'unrelated', updatedAt: DateTime.utc(2026, 1, 2)),
      );
      await db.echoSessionDao.upsert(_session(targetId: 'practiced'));

      final sub = container.listen(
        continuePracticeResumeProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _pumpUntil(
        () =>
            container.read(continuePracticeResumeProvider)?.media.id ==
            'practiced',
      );

      expect(registry.watchAllCalls, 0);
      expect(
        registry.watchByIdsCalls.any((ids) => ids.contains('practiced')),
        isTrue,
      );
    },
  );

  test(
    'craft history reads the provider view, never the whole catalog',
    () async {
      await db.audioDao.insertRow(
        _audio(
          id: 'craft-1',
          provider: 'craft',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.audioDao.insertRow(
        _audio(
          id: 'craft-2',
          provider: 'craft',
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
      );
      await db.audioDao.insertRow(
        _audio(id: 'user-1', updatedAt: DateTime.utc(2026, 3, 1)),
      );

      final sub = container.listen(
        craftHistoryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await _pumpUntil(() {
        final items = container.read(craftHistoryProvider).valueOrNull;
        return items != null && items.length == 2;
      });

      final items = container.read(craftHistoryProvider).requireValue;
      expect(items.map((m) => m.id).toList(), ['craft-2', 'craft-1']);
      expect(registry.watchAllCalls, 0);
      expect(registry.watchByProviderCalls, contains('craft'));
    },
  );
}
