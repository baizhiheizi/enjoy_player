/// Covers the [CloudAddToLibrary] add / in-library seam against an in-memory
/// Drift database.
///
/// [CloudAddToLibrary] dispatches on [RemoteLibraryItem.isVideo] into the
/// `videos` and `audios` tables, which are independent — no row shadows
/// another, and a shared id resolves per kind. This suite pins that
/// dispatch, the server-field mapping on both kinds, and the
/// insert-or-replace write.
library;

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/cloud/application/cloud_add_to_library.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _base = DateTime(2026, 7, 1);

enum _Kind {
  audio(isVideo: false, defaultDuration: 120),
  video(isVideo: true, defaultDuration: 360);

  const _Kind({required this.isVideo, required this.defaultDuration});

  final bool isVideo;
  final int defaultDuration;

  String get provider => isVideo ? 'youtube' : 'local';
  String get nativeIdKey => isVideo ? 'vid' : 'aid';
  String get nativeIdPrefix => isVideo ? 'vid_' : 'aid_';
}

Map<String, dynamic> _serverJson(
  _Kind kind,
  String id, {
  String? title,
  int? duration,
  String? mediaUrl,
  String? md5,
  int? size,
}) {
  return <String, dynamic>{
    'id': id,
    kind.nativeIdKey: '${kind.nativeIdPrefix}$id',
    'provider': kind.provider,
    'title': title ?? '${kind.name} $id',
    'duration': duration ?? kind.defaultDuration,
    'language': 'und',
    'mediaUrl': mediaUrl,
    'md5': md5,
    'size': size,
    'updatedAt': _base.toUtc().toIso8601String(),
    'createdAt': _base.toUtc().toIso8601String(),
  };
}

RemoteLibraryItem _item(
  _Kind kind,
  String id, {
  Map<String, dynamic>? rawJson,
}) {
  return RemoteLibraryItem(
    id: id,
    isVideo: kind.isVideo,
    title: '${kind.name} $id',
    thumbnailUrl: null,
    durationSeconds: kind.defaultDuration,
    language: 'und',
    mediaUrl: null,
    md5: null,
    size: null,
    provider: kind.provider,
    rawJson: rawJson ?? _serverJson(kind, id),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late CloudAddToLibrary addToLibrary;
  late MediaRegistry registry;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    addToLibrary = CloudAddToLibrary(db);
    registry = MediaRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('isInLibrary', () {
    test('returns false for an unknown audio id', () async {
      expect(await addToLibrary.isInLibrary(_item(_Kind.audio, 'a1')), isFalse);
    });

    test('returns false for an unknown video id', () async {
      expect(await addToLibrary.isInLibrary(_item(_Kind.video, 'v1')), isFalse);
    });

    test('returns true after the same audio id is added', () async {
      await addToLibrary.add(_item(_Kind.audio, 'a1'));
      expect(await addToLibrary.isInLibrary(_item(_Kind.audio, 'a1')), isTrue);
    });

    test('returns true after the same video id is added', () async {
      await addToLibrary.add(_item(_Kind.video, 'v1'));
      expect(await addToLibrary.isInLibrary(_item(_Kind.video, 'v1')), isTrue);
    });

    test('an audio probe does not read a video row with the same id', () async {
      await addToLibrary.add(_item(_Kind.video, 'shared'));
      expect(
        await addToLibrary.isInLibrary(_item(_Kind.audio, 'shared')),
        isFalse,
      );
    });

    test('a video probe does not read an audio row with the same id', () async {
      await addToLibrary.add(_item(_Kind.audio, 'shared'));
      expect(
        await addToLibrary.isInLibrary(_item(_Kind.video, 'shared')),
        isFalse,
      );
    });

    test(
      'both kinds stay in library when one id lands in both tables',
      () async {
        await addToLibrary.add(_item(_Kind.audio, 'shared'));
        await addToLibrary.add(_item(_Kind.video, 'shared'));

        expect(
          await addToLibrary.isInLibrary(_item(_Kind.audio, 'shared')),
          isTrue,
        );
        expect(
          await addToLibrary.isInLibrary(_item(_Kind.video, 'shared')),
          isTrue,
        );
      },
    );
  });

  group('add', () {
    test('inserts an audio row with the server fields preserved', () async {
      final raw = _serverJson(
        _Kind.audio,
        'a1',
        title: 'Track',
        duration: 240,
        mediaUrl: 'https://cdn.example/a1.mp3',
        md5: 'deadbeef',
        size: 4096,
      );
      await addToLibrary.add(_item(_Kind.audio, 'a1', rawJson: raw));

      final row = await registry.getAudioById('a1');
      expect(row, isNotNull);
      expect(row!.id, 'a1');
      expect(row.aid, 'aid_a1');
      expect(row.provider, 'local');
      expect(row.title, 'Track');
      expect(row.durationSeconds, 240);
      expect(row.language, 'und');
      expect(row.mediaUrl, 'https://cdn.example/a1.mp3');
      expect(row.md5, 'deadbeef');
      expect(row.size, 4096);
    });

    test('inserts a video row with the server fields preserved', () async {
      final raw = _serverJson(
        _Kind.video,
        'v1',
        title: 'Clip',
        duration: 720,
        mediaUrl: 'https://cdn.example/v1.mp4',
        md5: 'f00dface',
        size: 8192,
      );
      await addToLibrary.add(_item(_Kind.video, 'v1', rawJson: raw));

      final row = await registry.getVideoById('v1');
      expect(row, isNotNull);
      expect(row!.id, 'v1');
      expect(row.vid, 'vid_v1');
      expect(row.provider, 'youtube');
      expect(row.title, 'Clip');
      expect(row.durationSeconds, 720);
      expect(row.language, 'und');
      expect(row.mediaUrl, 'https://cdn.example/v1.mp4');
      expect(row.md5, 'f00dface');
      expect(row.size, 8192);
    });

    test('inserting an audio does not land a video row', () async {
      await addToLibrary.add(_item(_Kind.audio, 'a1'));
      expect(await registry.getVideoById('a1'), isNull);
    });

    test('inserting a video does not land an audio row', () async {
      await addToLibrary.add(_item(_Kind.video, 'v1'));
      expect(await registry.getAudioById('v1'), isNull);
    });

    test('re-adding an existing audio replaces every row field', () async {
      final first = _serverJson(
        _Kind.audio,
        'a1',
        title: 'First',
        mediaUrl: 'https://cdn.example/first.mp3',
        md5: 'aaaa',
        size: 11,
      );
      final second = _serverJson(
        _Kind.audio,
        'a1',
        title: 'Second',
        mediaUrl: 'https://cdn.example/second.mp3',
        md5: 'bbbb',
        size: 22,
      );
      await addToLibrary.add(_item(_Kind.audio, 'a1', rawJson: first));
      await addToLibrary.add(_item(_Kind.audio, 'a1', rawJson: second));

      final row = await registry.getAudioById('a1');
      expect(row, isNotNull);
      expect(row!.id, 'a1');
      expect(row.aid, 'aid_a1');
      expect(row.provider, 'local');
      expect(row.title, 'Second');
      expect(row.mediaUrl, 'https://cdn.example/second.mp3');
      expect(row.md5, 'bbbb');
      expect(row.size, 22);
    });
  });
}
