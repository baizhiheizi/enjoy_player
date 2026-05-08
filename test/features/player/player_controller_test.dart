import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerController', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;

    Future<String> insertMedia({
      required String id,
      required String uri,
      String kind = 'audio',
    }) async {
      final now = DateTime.now();
      if (kind == 'video') {
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 600,
            language: 'en',
            source: null,
            localUri: uri,
            md5: null,
            size: 1,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 600,
            language: 'en',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: uri,
            md5: null,
            size: 1,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      return id;
    }

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      fake = FakePlayerEngine();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineProvider.overrideWithValue(fake),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    test('openMedia loads row and sets session', () async {
      final id = await insertMedia(id: 'm1', uri: 'file:///a.mp3');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      final session = container.read(playerControllerProvider);
      expect(session, isNotNull);
      expect(session!.mediaId, id);
      expect(session.mediaTitle, 't');
      expect(session.dexieTargetType, 'Audio');
      expect(fake.openUris, contains('file:///a.mp3'));
    });

    test('openMedia ignores stale completion when superseded', () async {
      fake.openDelay = () => Future<void>.delayed(const Duration(milliseconds: 250));
      final idA = await insertMedia(id: 'a', uri: 'file:///a.mp3');
      final idB = await insertMedia(id: 'b', uri: 'file:///b.mp3');

      final n = container.read(playerControllerProvider.notifier);
      final f1 = n.openMedia(idA);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final f2 = n.openMedia(idB);
      await Future.wait([f1, f2]);

      expect(container.read(playerControllerProvider)?.mediaId, idB);
    });

    test('debounced session persistence writes position', () async {
      final id = await insertMedia(id: 'm1', uri: 'file:///a.mp3');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      fake.emitDuration(const Duration(seconds: 120));
      fake.emitPosition(const Duration(seconds: 7));

      await Future<void>.delayed(const Duration(milliseconds: 550));

      final row = await db.echoSessionDao.getLatestForTarget('Audio', id);
      expect(row, isNotNull);
      expect(row!.currentTimeMs, closeTo(7000, 50));
    });

    test('echo mode seeks back into window', () async {
      final id = await insertMedia(id: 'm1', uri: 'file:///a.mp3');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      container
          .read(echoModeProvider.notifier)
          .activate(
            startLineIndex: 0,
            endLineIndex: 1,
            startTimeSeconds: 2,
            endTimeSeconds: 5,
          );

      fake.emitPosition(const Duration(milliseconds: 500));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fake.seekCalls, isNotEmpty);
      expect(
        fake.seekCalls.last,
        const Duration(milliseconds: 2000),
      );
    });
  });
}
