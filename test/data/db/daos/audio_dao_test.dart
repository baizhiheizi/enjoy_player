import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';

AudioRow _audioRow({
  String id = 'a-1',
  String aid = 'aid-1',
  String provider = 'user',
  String title = 'Hello',
  int durationSeconds = 0,
  String language = 'und',
  String? md5,
  String? localUri,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return AudioRow(
    id: id,
    aid: aid,
    provider: provider,
    title: title,
    durationSeconds: durationSeconds,
    language: language,
    md5: md5,
    localUri: localUri,
    createdAt: now,
    updatedAt: now,
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

  group('AudioDao', () {
    test('insertRow persists and getById reads it back', () async {
      await db.audioDao.insertRow(_audioRow(id: 'a'));
      final found = await db.audioDao.getById('a');
      expect(found, isNotNull);
      expect(found!.id, 'a');
      expect(found.title, 'Hello');
    });

    test('insertRow with same primary key replaces existing row', () async {
      await db.audioDao.insertRow(_audioRow(id: 'a', title: 'first'));
      await db.audioDao.insertRow(_audioRow(id: 'a', title: 'second'));
      final found = await db.audioDao.getById('a');
      expect(found!.title, 'second');
    });

    test('getById returns null for missing id', () async {
      expect(await db.audioDao.getById('missing'), isNull);
    });

    test('getByMd5 returns row with matching md5', () async {
      await db.audioDao.insertRow(_audioRow(id: 'a', md5: 'abc'));
      await db.audioDao.insertRow(_audioRow(id: 'b', md5: 'xyz'));
      final found = await db.audioDao.getByMd5('xyz');
      expect(found, isNotNull);
      expect(found!.id, 'b');
    });

    test('getByMd5 returns null when no match', () async {
      await db.audioDao.insertRow(_audioRow(id: 'a', md5: 'abc'));
      expect(await db.audioDao.getByMd5('zzz'), isNull);
    });

    test('updateLanguage changes language and bumps updatedAt', () async {
      await db.audioDao.insertRow(_audioRow(id: 'a'));
      final before = await db.audioDao.getById('a');
      final beforeTs = before!.updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.audioDao.updateLanguage(id: 'a', language: 'en');
      final after = await db.audioDao.getById('a');
      expect(after!.language, 'en');
      expect(after.updatedAt.isAfter(beforeTs), isTrue);
    });

    test('updateLanguage is a no-op for missing id (still executes)', () async {
      await db.audioDao.updateLanguage(id: 'missing', language: 'en');
      expect(await db.audioDao.getById('missing'), isNull);
    });

    test(
      'touchUpdatedAt bumps updatedAt without changing other fields',
      () async {
        await db.audioDao.insertRow(_audioRow(id: 'a', title: 'Hi'));
        final before = await db.audioDao.getById('a');
        final beforeTs = before!.updatedAt;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await db.audioDao.touchUpdatedAt('a');
        final after = await db.audioDao.getById('a');
        expect(after!.title, 'Hi');
        expect(after.updatedAt.isAfter(beforeTs), isTrue);
      },
    );

    test('deleteId removes the row', () async {
      await db.audioDao.insertRow(_audioRow(id: 'kill'));
      await db.audioDao.insertRow(_audioRow(id: 'keep'));
      await db.audioDao.deleteId('kill');
      expect(await db.audioDao.getById('kill'), isNull);
      expect(await db.audioDao.getById('keep'), isNotNull);
    });

    test('existsByLocalUri returns true for matching rows', () async {
      await db.audioDao.insertRow(_audioRow(id: '1', localUri: 'file://1'));
      await db.audioDao.insertRow(_audioRow(id: '2', localUri: 'file://1'));
      await db.audioDao.insertRow(_audioRow(id: '3', localUri: 'file://2'));
      expect(await db.audioDao.existsByLocalUri('file://1'), isTrue);
      expect(await db.audioDao.existsByLocalUri('file://2'), isTrue);
      expect(await db.audioDao.existsByLocalUri('file://3'), isFalse);
    });

    test('watchAll emits rows ordered by createdAt descending', () async {
      final older = DateTime.utc(2026, 1, 1);
      final newer = DateTime.utc(2026, 6, 1);
      await db.audioDao.insertRow(
        _audioRow(id: 'old').copyWith(createdAt: older, updatedAt: older),
      );
      await db.audioDao.insertRow(
        _audioRow(id: 'new').copyWith(createdAt: newer, updatedAt: newer),
      );
      final list = await db.audioDao.watchAll().first;
      expect(list.map((r) => r.id), ['new', 'old']);
    });

    test('watchAll projects every field Media needs', () async {
      final when = DateTime.utc(2026, 5, 1);
      await db.audioDao.insertRow(
        _audioRow(
          id: 'a-full',
          aid: 'aid-full',
          provider: 'craft',
          title: 'Crafted clip',
          durationSeconds: 33,
          language: 'en',
        ).copyWith(
          thumbnailUrl: const Value('file:///tmp/a.jpg'),
          source: const Value('Craft'),
          localUri: const Value('file:///tmp/a.wav'),
          size: const Value(7),
          mediaUrl: const Value('https://example.com/a'),
          syncStatus: const Value('synced'),
          createdAt: when,
          updatedAt: when,
        ),
      );

      final rows = await db.audioDao.watchAll().first;
      final media = mediaFromLibraryProjection(
        rows.single,
        kind: MediaKind.audio,
      );

      expect(media.id, 'a-full');
      expect(media.kind, MediaKind.audio);
      expect(media.title, 'Crafted clip');
      expect(media.sourceUri, 'file:///tmp/a.wav');
      expect(media.thumbnailPath, 'file:///tmp/a.jpg');
      expect(media.durationMs, 33000);
      expect(media.language, 'en');
      expect(media.contentHash, 'aid-full');
      expect(media.fileSize, 7);
      expect(media.mediaUrl, 'https://example.com/a');
      expect(media.source, 'Craft');
      expect(media.provider, 'craft');
      expect(media.syncStatus, 'synced');
      expect(media.createdAt.toUtc(), when);
      expect(media.updatedAt.toUtc(), when);
    });

    test('watchRecentByUpdatedAt returns top rows by updatedAt desc', () async {
      final base = DateTime.utc(2026, 4, 1);
      await db.audioDao.insertRow(
        _audioRow(id: 'a-stale').copyWith(
          createdAt: base,
          updatedAt: base.add(const Duration(days: 1)),
        ),
      );
      await db.audioDao.insertRow(
        _audioRow(id: 'a-fresh').copyWith(
          createdAt: base,
          updatedAt: base.add(const Duration(days: 2)),
        ),
      );

      final top1 = await db.audioDao.watchRecentByUpdatedAt(1).first;
      expect(top1.map((r) => r.id).toList(), ['a-fresh']);
    });
  });

  group('SettingsDao', () {
    test('getValue returns null for unset key', () async {
      expect(
        await db.settingsDao.getValue(SettingsKeys.apiBaseUrl.name),
        isNull,
      );
    });

    test('setValue then getValue round-trips a string', () async {
      await db.settingsDao.setValue(SettingsKeys.apiBaseUrl.name, 'https://x');
      expect(
        await db.settingsDao.getValue(SettingsKeys.apiBaseUrl.name),
        'https://x',
      );
    });

    test('setValue with same key overwrites prior value', () async {
      await db.settingsDao.setValue(SettingsKeys.apiBaseUrl.name, 'https://a');
      await db.settingsDao.setValue(SettingsKeys.apiBaseUrl.name, 'https://b');
      expect(
        await db.settingsDao.getValue(SettingsKeys.apiBaseUrl.name),
        'https://b',
      );
    });

    test('setValue allows several distinct keys', () async {
      await db.settingsDao.setValue(SettingsKeys.apiBaseUrl.name, 'a');
      await db.settingsDao.setValue(SettingsKeys.prefsLocale.name, 'zh-CN');
      expect(await db.settingsDao.getValue(SettingsKeys.apiBaseUrl.name), 'a');
      expect(
        await db.settingsDao.getValue(SettingsKeys.prefsLocale.name),
        'zh-CN',
      );
    });

    test('deleteValue removes a previously stored key', () async {
      await db.settingsDao.setValue(SettingsKeys.apiBaseUrl.name, 'x');
      await db.settingsDao.deleteValue(SettingsKeys.apiBaseUrl.name);
      expect(
        await db.settingsDao.getValue(SettingsKeys.apiBaseUrl.name),
        isNull,
      );
    });

    test('deleteValue is a no-op for unknown keys', () async {
      await db.settingsDao.deleteValue(SettingsKeys.apiBaseUrl.name);
      expect(
        await db.settingsDao.getValue(SettingsKeys.apiBaseUrl.name),
        isNull,
      );
    });

    test('dynamic sync cursor keys are accepted', () async {
      final key = SettingsKeys.syncCursorRecordingTarget('video', 'v-1');
      await db.settingsDao.setValue(key, 'cursor-1');
      expect(await db.settingsDao.getValue(key), 'cursor-1');
      await db.settingsDao.deleteValue(key);
      expect(await db.settingsDao.getValue(key), isNull);
    });

    test('SettingsKeys.isKnown covers static and dynamic families', () {
      expect(SettingsKeys.isKnown(SettingsKeys.apiBaseUrl.name), isTrue);
      expect(SettingsKeys.isKnown(SettingsKeys.prefsLocale.name), isTrue);
      expect(SettingsKeys.isKnown(SettingsKeys.updateLastCheckAt.name), isTrue);
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncCursorRecordingTarget('video', 'v-1'),
        ),
        isTrue,
      );
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncLastPullAtRecordingTarget('audio', 'a-1'),
        ),
        isTrue,
      );
      expect(
        SettingsKeys.isKnown(SettingsKeys.asrLongFormAttempt('m-1')),
        isTrue,
      );
      expect(SettingsKeys.isKnown('definitely.not.known'), isFalse);
      expect(SettingsKeys.isKnown(''), isFalse);
      expect(SettingsKeys.isKnown('sync.cursor.unknown'), isFalse);
    });
  });
}
