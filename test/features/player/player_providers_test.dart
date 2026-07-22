import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/fake_player_engine.dart';
import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player engine / display providers', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;
    late Directory pathProviderRoot;

    setUp(() {
      originalPathProvider = PathProviderPlatform.instance;
      pathProviderRoot = Directory.systemTemp.createTempSync(
        'enjoy_player_prov_path',
      );
      PathProviderPlatform.instance = TestPathProvider(pathProviderRoot.path);

      db = AppDatabase(executor: NativeDatabase.memory());
      fake = FakePlayerEngine();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
        ],
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      if (pathProviderRoot.existsSync()) {
        pathProviderRoot.deleteSync(recursive: true);
      }
      await pumpEventQueue();
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    Future<String> insertAudio(String id) async {
      final now = DateTime.now();
      final tmp = File(
        p.join(
          Directory.systemTemp.path,
          'enjoy_prov_${id}_${DateTime.now().microsecondsSinceEpoch}.mp3',
        ),
      );
      await tmp.writeAsBytes([1]);
      final uri = Uri.file(tmp.path).toString();
      await db.audioDao.insertRow(
        AudioRow(
          id: id,
          aid: 'x',
          provider: 'user',
          title: 't',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 120,
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
      return id;
    }

    test('playerEngineProvider exposes test double', () async {
      final id = await insertAudio('e1');
      await container.read(playerControllerProvider.notifier).openMedia(id);
      expect(container.read(playerEngineProvider), same(fake));
    });

    test(
      'playerIsPlayingProvider seeds from engine transportSnapshot',
      () async {
        final id = await insertAudio('e2');
        await container.read(playerControllerProvider.notifier).openMedia(id);
        bool? last;
        container.listen(playerIsPlayingProvider, (_, n) {
          if (n.hasValue) last = n.requireValue;
        }, fireImmediately: true);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(last, isFalse);
      },
    );

    test('displayPositionProvider quantizes to 400ms buckets', () async {
      final id = await insertAudio('e3');
      await container.read(playerControllerProvider.notifier).openMedia(id);

      Duration? last;
      final sub = container.listen(displayPositionProvider, (_, n) {
        if (n.hasValue) last = n.requireValue;
      }, fireImmediately: true);

      fake.emitPosition(const Duration(milliseconds: 430));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(last, const Duration(milliseconds: 400));

      fake.emitPosition(const Duration(milliseconds: 850));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(last, const Duration(milliseconds: 800));

      sub.close();
    });
  });
}
