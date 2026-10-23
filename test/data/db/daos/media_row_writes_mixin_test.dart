import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Snapshot = ({
  String title,
  String language,
  int durationSeconds,
  DateTime updatedAt,
  String? localUri,
});

class _Harness {
  const _Harness({
    required this.name,
    required this.insert,
    required this.snapshot,
    required this.updateTitle,
    required this.updateLanguage,
    required this.touchUpdatedAt,
    required this.setDurationIfZero,
    required this.deleteId,
    required this.existsByLocalUri,
  });

  final String name;
  final Future<void> Function({
    required String id,
    required int durationSeconds,
    String? localUri,
  })
  insert;
  final Future<_Snapshot?> Function(String id) snapshot;
  final Future<void> Function(String id, String title) updateTitle;
  final Future<void> Function(String id, String language) updateLanguage;
  final Future<void> Function(String id) touchUpdatedAt;
  final Future<bool> Function(String id, int durationSeconds) setDurationIfZero;
  final Future<void> Function(String id) deleteId;
  final Future<bool> Function(String localUri) existsByLocalUri;
}

_Harness _audioHarness(AppDatabase db) {
  final created = DateTime.utc(2020);
  return _Harness(
    name: 'AudioDao',
    insert: ({required id, required durationSeconds, localUri}) =>
        db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'aid-$id',
            provider: 'user',
            title: 'title',
            durationSeconds: durationSeconds,
            language: 'und',
            localUri: localUri,
            createdAt: created,
            updatedAt: created,
          ),
        ),
    snapshot: (id) async {
      final row = await db.audioDao.getById(id);
      if (row == null) return null;
      return (
        title: row.title,
        language: row.language,
        durationSeconds: row.durationSeconds,
        updatedAt: row.updatedAt,
        localUri: row.localUri,
      );
    },
    updateTitle: (id, title) => db.audioDao.updateTitle(id: id, title: title),
    updateLanguage: (id, language) =>
        db.audioDao.updateLanguage(id: id, language: language),
    touchUpdatedAt: db.audioDao.touchUpdatedAt,
    setDurationIfZero: db.audioDao.setDurationIfZero,
    deleteId: db.audioDao.deleteId,
    existsByLocalUri: db.audioDao.existsByLocalUri,
  );
}

_Harness _videoHarness(AppDatabase db) {
  final created = DateTime.utc(2020);
  return _Harness(
    name: 'VideoDao',
    insert: ({required id, required durationSeconds, localUri}) =>
        db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'vid-$id',
            provider: 'user',
            title: 'title',
            durationSeconds: durationSeconds,
            language: 'und',
            localUri: localUri,
            createdAt: created,
            updatedAt: created,
          ),
        ),
    snapshot: (id) async {
      final row = await db.videoDao.getById(id);
      if (row == null) return null;
      return (
        title: row.title,
        language: row.language,
        durationSeconds: row.durationSeconds,
        updatedAt: row.updatedAt,
        localUri: row.localUri,
      );
    },
    updateTitle: (id, title) => db.videoDao.updateTitle(id: id, title: title),
    updateLanguage: (id, language) =>
        db.videoDao.updateLanguage(id: id, language: language),
    touchUpdatedAt: db.videoDao.touchUpdatedAt,
    setDurationIfZero: db.videoDao.setDurationIfZero,
    deleteId: db.videoDao.deleteId,
    existsByLocalUri: db.videoDao.existsByLocalUri,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  void register(String name, _Harness Function(AppDatabase) build) {
    group(name, () {
      late _Harness harness;

      setUp(() {
        harness = build(db);
      });

      test('setDurationIfZero patches a zero duration exactly once', () async {
        await harness.insert(id: 'm', durationSeconds: 0);

        expect(await harness.setDurationIfZero('m', 42), isTrue);
        expect((await harness.snapshot('m'))!.durationSeconds, 42);

        expect(await harness.setDurationIfZero('m', 99), isFalse);
        expect((await harness.snapshot('m'))!.durationSeconds, 42);
        expect(await harness.setDurationIfZero('missing', 7), isFalse);
      });

      test('updateTitle and updateLanguage bump updatedAt', () async {
        await harness.insert(id: 'm', durationSeconds: 1);

        await harness.updateTitle('m', 'Renamed');
        final titled = (await harness.snapshot('m'))!;
        expect(titled.title, 'Renamed');
        expect(titled.updatedAt.isAfter(DateTime.utc(2020)), isTrue);

        await harness.updateLanguage('m', 'de');
        final languaged = (await harness.snapshot('m'))!;
        expect(languaged.language, 'de');
        expect(languaged.updatedAt.isBefore(titled.updatedAt), isFalse);
      });

      test('touchUpdatedAt preserves every other field', () async {
        await harness.insert(id: 'm', durationSeconds: 3);

        await harness.touchUpdatedAt('m');
        final row = (await harness.snapshot('m'))!;
        expect(row.title, 'title');
        expect(row.durationSeconds, 3);
        expect(row.updatedAt.isAfter(DateTime.utc(2020)), isTrue);
      });

      test('existsByLocalUri matches an exact local uri', () async {
        await harness.insert(id: 'a', durationSeconds: 0, localUri: 'file://a');

        expect(await harness.existsByLocalUri('file://a'), isTrue);
        expect(await harness.existsByLocalUri('file://b'), isFalse);
      });

      test('deleteId removes only the requested row', () async {
        await harness.insert(id: 'gone', durationSeconds: 0);
        await harness.insert(id: 'kept', durationSeconds: 0);

        await harness.deleteId('gone');
        expect(await harness.snapshot('gone'), isNull);
        expect(await harness.snapshot('kept'), isNotNull);
      });
    });
  }

  register('AudioDao', _audioHarness);
  register('VideoDao', _videoHarness);
}
