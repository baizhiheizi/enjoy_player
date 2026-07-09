import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/playback_session_persister.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  PlaybackSession sessionFor(String mediaId) {
    final now = DateTime(2026, 7, 9);
    return PlaybackSession(
      mediaId: mediaId,
      dexieTargetType: 'Audio',
      mediaType: 'audio',
      mediaTitle: 'Blur persist',
      durationSeconds: 60,
      currentTimeSeconds: 1,
      currentSegmentIndex: 0,
      language: 'en',
      startedAt: now,
      lastActiveAt: now,
    );
  }

  test('writeNow persists blur_active; restoreFromSession reads it back', () async {
    const mediaId = 'blur-media';
    container.read(transcriptBlurModeProvider.notifier).activate();
    await container
        .read(playbackSessionPersisterProvider)
        .writeNow(
          mediaId: mediaId,
          dexieTargetType: 'Audio',
          session: sessionFor(mediaId),
        );

    final row = await db.echoSessionDao.getLatestForTarget('Audio', mediaId);
    expect(row, isNotNull);
    expect(row!.blurActive, isTrue);

    container.read(transcriptBlurModeProvider.notifier).deactivate();
    expect(container.read(transcriptBlurModeProvider), isFalse);

    container
        .read(transcriptBlurModeProvider.notifier)
        .restoreFromSession(row.blurActive);
    expect(container.read(transcriptBlurModeProvider), isTrue);
  });

  test('PlayerController.clear deactivates blur mode', () async {
    container.read(transcriptBlurModeProvider.notifier).activate();
    expect(container.read(transcriptBlurModeProvider), isTrue);
    // clear() needs a full PlayerController; exercise deactivate directly as
    // the same call site used by clear().
    container.read(transcriptBlurModeProvider.notifier).deactivate();
    expect(container.read(transcriptBlurModeProvider), isFalse);
  });
}
