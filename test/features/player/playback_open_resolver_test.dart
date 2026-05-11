import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/player/application/playback_open_resolver.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('resolvePlaybackOpen returns null for unknown id', () async {
    expect(await resolvePlaybackOpen(db, 'missing'), isNull);
  });

  test('resolvePlaybackOpen throws when playable missing but hash set', () async {
    final now = DateTime.now();
    const id = 'x1';
    const fingerprint =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final missingPath = p.join(
      Directory.systemTemp.path,
      'enjoy_missing_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    await db.videoDao.insertRow(
      VideoRow(
        id: id,
        vid: fingerprint,
        provider: 'user',
        title: 't',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 1,
        language: 'en',
        source: null,
        localUri: Uri.file(missingPath).toString(),
        md5: fingerprint,
        size: 1,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await expectLater(
      resolvePlaybackOpen(db, id),
      throwsA(isA<MediaNeedsRelocateException>()),
    );
  });

  test(
    'resolvePlaybackOpen uses YouTube when vid is id despite user provider',
    () async {
      final now = DateTime.now();
      const id = 'yt-bad-provider-1';
      await db.videoDao.insertRow(
        VideoRow(
          id: id,
          vid: 'dQw4w9WgXcQ',
          provider: 'user',
          title: 't',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 1,
          language: 'en',
          source: null,
          localUri: null,
          md5: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final r = await resolvePlaybackOpen(db, id);
      expect(r, isNotNull);
      expect(r!.playable, isA<YoutubePlayableSource>());
      expect((r.playable as YoutubePlayableSource).videoId, 'dQw4w9WgXcQ');
    });
}
