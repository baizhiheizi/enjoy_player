import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/fake_player_engine.dart';
import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerController', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;
    late Directory pathProviderRoot;

    Future<String> insertMedia({
      required String id,
      String kind = 'audio',
      String? localUri,
      String? mediaUrl,
      String? md5,
      String? thumbnailUrl,
    }) async {
      final now = DateTime.now();
      late final String effectiveLocal;
      if (localUri != null) {
        effectiveLocal = localUri;
      } else {
        final ext = kind == 'video' ? '.mp4' : '.mp3';
        final tmp = File(
          p.join(
            Directory.systemTemp.path,
            'enjoy_player_ctrl_${id}_${DateTime.now().microsecondsSinceEpoch}$ext',
          ),
        );
        await tmp.writeAsBytes([1]);
        effectiveLocal = Uri.file(tmp.path).toString();
      }
      if (kind == 'video') {
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: thumbnailUrl,
            durationSeconds: 600,
            language: 'en',
            source: null,
            localUri: effectiveLocal,
            md5: md5,
            size: 1,
            mediaUrl: mediaUrl,
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
            thumbnailUrl: thumbnailUrl,
            durationSeconds: 600,
            language: 'en',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: effectiveLocal,
            md5: md5,
            size: 1,
            mediaUrl: mediaUrl,
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
      originalPathProvider = PathProviderPlatform.instance;
      pathProviderRoot = Directory.systemTemp.createTempSync(
        'enjoy_player_ctrl_path',
      );
      PathProviderPlatform.instance = TestPathProvider(pathProviderRoot.path);

      db = AppDatabase(executor: NativeDatabase.memory());
      fake = FakePlayerEngine();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(TranscriptRepository(db)),
        ],
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      if (pathProviderRoot.existsSync()) {
        pathProviderRoot.deleteSync(recursive: true);
      }

      container.dispose();
      await db.close();
      await fake.dispose();
    });

    test('openMedia loads row and sets session', () async {
      final id = await insertMedia(id: 'm1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      final session = container.read(playerControllerProvider);
      expect(session, isNotNull);
      expect(session!.mediaId, id);
      expect(session.mediaTitle, 't');
      expect(session.dexieTargetType, 'Audio');
      expect(fake.openUris, hasLength(1));
      expect(fake.openUris.single, startsWith('file:'));
    });

    test('openMedia same id again does not reload uri', () async {
      final id = await insertMedia(id: 'm1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      final firstUri = fake.openUris.single;
      await n.openMedia(id);

      expect(fake.openUris, [firstUri]);
    });

    test('openMedia ignores stale completion when superseded', () async {
      fake.openDelay = () => Future<void>.delayed(const Duration(milliseconds: 250));
      final idA = await insertMedia(id: 'a');
      final idB = await insertMedia(id: 'b');

      final n = container.read(playerControllerProvider.notifier);
      final f1 = n.openMedia(idA);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final f2 = n.openMedia(idB);
      await Future.wait([f1, f2]);

      expect(container.read(playerControllerProvider)?.mediaId, idB);
    });

    test('debounced session persistence writes position', () async {
      final id = await insertMedia(id: 'm1');
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
      final id = await insertMedia(id: 'm1');
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

    test('openMedia throws MediaNeedsRelocateException when local missing and hash set', () async {
      final now = DateTime.now();
      const id = 'reloc-1';
      const fingerprint = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final missingPath = p.join(
        Directory.systemTemp.path,
        'enjoy_missing_${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      final uri = Uri.file(missingPath).toString();

      await db.videoDao.insertRow(
        VideoRow(
          id: id,
          vid: fingerprint,
          provider: 'user',
          title: 'From sync',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 1,
          language: 'en',
          source: null,
          localUri: uri,
          md5: fingerprint,
          size: 100,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final n = container.read(playerControllerProvider.notifier);
      await expectLater(
        n.openMedia(id),
        throwsA(isA<MediaNeedsRelocateException>()),
      );
      expect(fake.openUris, isEmpty);
    });

    test('openMedia uses mediaUrl when local file is missing', () async {
      final id = await insertMedia(
        id: 'net-1',
        localUri: Uri.file(
          p.join(
            Directory.systemTemp.path,
            'surely_missing_${DateTime.now().microsecondsSinceEpoch}.mp3',
          ),
        ).toString(),
        mediaUrl: 'https://example.com/media.mp4',
        md5: 'any',
      );
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      expect(fake.openUris, ['https://example.com/media.mp4']);
    });

    test('openMedia persists video poster from screenshot when thumbnail missing', () async {
      const hash =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final id = await insertMedia(id: 'v-cap', kind: 'video', md5: hash);
      fake.screenshotReturnValue = Uint8List.fromList(const [10, 11, 12]);
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(fake.screenshotCalls, greaterThanOrEqualTo(1));
      final row = await db.videoDao.getById(id);
      expect(row!.thumbnailUrl, isNotNull);
      final thumbFile = File(row.thumbnailUrl!);
      expect(thumbFile.existsSync(), isTrue);
      expect(await thumbFile.readAsBytes(), fake.screenshotReturnValue);

      final session = container.read(playerControllerProvider);
      expect(session?.thumbnailUrl, row.thumbnailUrl);
    });

    test('openMedia skips poster capture when remote thumbnail url set', () async {
      final id = await insertMedia(
        id: 'v-remote',
        kind: 'video',
        thumbnailUrl: 'https://cdn.example/x.jpg',
      );
      fake.screenshotReturnValue = Uint8List.fromList(const [1, 2, 3]);
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(fake.screenshotCalls, 0);
    });

    test('openMedia skips poster capture when local thumbnail file exists', () async {
      final tmp = File(
        p.join(
          Directory.systemTemp.path,
          'enjoy_thumb_${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );
      await tmp.writeAsBytes(const [1, 2, 3]);
      final id = await insertMedia(
        id: 'v-has-thumb',
        kind: 'video',
        thumbnailUrl: tmp.path,
      );
      fake.screenshotReturnValue = Uint8List.fromList(const [9, 9, 9]);
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(fake.screenshotCalls, 0);
    });

    test('openMedia does not capture poster for audio', () async {
      final id = await insertMedia(id: 'a-cap');
      fake.screenshotReturnValue = Uint8List.fromList(const [1]);
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(fake.screenshotCalls, 0);
    });
  });
}
