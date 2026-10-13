/// Covers the [CloudAddToLibrary] add/in-library seam against an in-memory
/// Drift database. The application layer is the only entry point for
/// `libraryMediaProvider` invalidation from the cloud list/grid tiles, so
/// the read + write pair is pinned here to keep the kind-dispatch contract
/// aligned with [MediaRegistry]'s video-first precedence.
library;

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/cloud/application/cloud_add_to_library.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _base = DateTime(2026, 7, 1);

Map<String, dynamic> _audioServerJson(
  String id, {
  String title = 'Audio',
  int duration = 120,
  String? mediaUrl,
  String? md5,
  int? size,
}) {
  return <String, dynamic>{
    'id': id,
    'aid': 'aid_$id',
    'provider': 'local',
    'title': title,
    'duration': duration,
    'language': 'und',
    'mediaUrl': mediaUrl,
    'md5': md5,
    'size': size,
    'updatedAt': _base.toUtc().toIso8601String(),
    'createdAt': _base.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> _videoServerJson(
  String id, {
  String title = 'Video',
  int duration = 360,
  String? mediaUrl,
  String? md5,
  int? size,
}) {
  return <String, dynamic>{
    'id': id,
    'vid': 'vid_$id',
    'provider': 'youtube',
    'title': title,
    'duration': duration,
    'language': 'und',
    'mediaUrl': mediaUrl,
    'md5': md5,
    'size': size,
    'updatedAt': _base.toUtc().toIso8601String(),
    'createdAt': _base.toUtc().toIso8601String(),
  };
}

RemoteLibraryItem _audioItem(String id, {Map<String, dynamic>? rawJson}) {
  return RemoteLibraryItem(
    id: id,
    isVideo: false,
    title: 'Audio $id',
    thumbnailUrl: null,
    durationSeconds: 120,
    language: 'und',
    mediaUrl: null,
    md5: null,
    size: null,
    provider: 'local',
    rawJson: rawJson ?? _audioServerJson(id),
  );
}

RemoteLibraryItem _videoItem(String id, {Map<String, dynamic>? rawJson}) {
  return RemoteLibraryItem(
    id: id,
    isVideo: true,
    title: 'Video $id',
    thumbnailUrl: null,
    durationSeconds: 360,
    language: 'und',
    mediaUrl: null,
    md5: null,
    size: null,
    provider: 'youtube',
    rawJson: rawJson ?? _videoServerJson(id),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late CloudAddToLibrary addToLibrary;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    addToLibrary = CloudAddToLibrary(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('isInLibrary', () {
    test('returns false for an unknown audio id', () async {
      expect(await addToLibrary.isInLibrary(_audioItem('a1')), isFalse);
    });

    test('returns false for an unknown video id', () async {
      expect(await addToLibrary.isInLibrary(_videoItem('v1')), isFalse);
    });

    test('returns true after the same audio id is added', () async {
      await addToLibrary.add(_audioItem('a1'));
      expect(await addToLibrary.isInLibrary(_audioItem('a1')), isTrue);
    });

    test('returns true after the same video id is added', () async {
      await addToLibrary.add(_videoItem('v1'));
      expect(await addToLibrary.isInLibrary(_videoItem('v1')), isTrue);
    });

    test('audio probe does not match a video row with the same id', () async {
      await addToLibrary.add(_videoItem('shared'));
      expect(await addToLibrary.isInLibrary(_audioItem('shared')), isFalse);
    });
  });

  group('add', () {
    test('inserts an audio row with the server fields preserved', () async {
      final raw = _audioServerJson(
        'a1',
        title: 'Track',
        duration: 240,
        mediaUrl: 'https://cdn.example/a1.mp3',
        md5: 'deadbeef',
        size: 4096,
      );
      await addToLibrary.add(_audioItem('a1', rawJson: raw));

      final row = await MediaRegistry(db).getAudioById('a1');
      expect(row, isNotNull);
      expect(row!.title, 'Track');
      expect(row.durationSeconds, 240);
      expect(row.mediaUrl, 'https://cdn.example/a1.mp3');
      expect(row.md5, 'deadbeef');
      expect(row.size, 4096);
    });

    test('inserts a video row with the server fields preserved', () async {
      final raw = _videoServerJson(
        'v1',
        title: 'Clip',
        duration: 720,
        mediaUrl: 'https://cdn.example/v1.mp4',
        md5: 'f00dface',
        size: 8192,
      );
      await addToLibrary.add(_videoItem('v1', rawJson: raw));

      final row = await MediaRegistry(db).getVideoById('v1');
      expect(row, isNotNull);
      expect(row!.title, 'Clip');
      expect(row.durationSeconds, 720);
      expect(row.mediaUrl, 'https://cdn.example/v1.mp4');
      expect(row.md5, 'f00dface');
      expect(row.size, 8192);
    });

    test('inserting an audio does not land a video row', () async {
      await addToLibrary.add(_audioItem('a1'));
      expect(await MediaRegistry(db).getVideoById('a1'), isNull);
    });

    test('inserting a video does not land an audio row', () async {
      await addToLibrary.add(_videoItem('v1'));
      expect(await MediaRegistry(db).getAudioById('v1'), isNull);
    });

    test(
      're-adding an existing audio replaces the row (insertOrReplace)',
      () async {
        final rawA = _audioServerJson('a1', title: 'First');
        final rawB = _audioServerJson('a1', title: 'Second');
        await addToLibrary.add(_audioItem('a1', rawJson: rawA));
        await addToLibrary.add(_audioItem('a1', rawJson: rawB));

        final row = await MediaRegistry(db).getAudioById('a1');
        expect(row, isNotNull);
        expect(row!.title, 'Second');
      },
    );
  });
}
