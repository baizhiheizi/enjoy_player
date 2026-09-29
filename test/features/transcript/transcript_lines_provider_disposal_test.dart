import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'media-disposal';
const _otherMediaId = 'media-other';
const _lines = <TranscriptLine>[
  TranscriptLine(text: 'hello', startMs: 0, durationMs: 500),
];

class _WatchSpyRepo extends TranscriptRepository {
  _WatchSpyRepo(super.db);

  final primaryCancels = <String>[];
  final secondaryCancels = <String>[];
  final primaryWatches = <String>[];
  final secondaryWatches = <String>[];
  final _controllers = <StreamController<List<TranscriptLine>>>[];

  @override
  Stream<List<TranscriptLine>> watchPrimaryLines(String mediaId) {
    primaryWatches.add(mediaId);
    return _watchStream(() => primaryCancels.add(mediaId));
  }

  @override
  Stream<List<TranscriptLine>> watchSecondaryLines(String mediaId) {
    secondaryWatches.add(mediaId);
    return _watchStream(() => secondaryCancels.add(mediaId));
  }

  Stream<List<TranscriptLine>> _watchStream(void Function() onCancel) {
    final controller = StreamController<List<TranscriptLine>>(
      onCancel: onCancel,
    );
    _controllers.add(controller);
    controller.add(_lines);
    return controller.stream;
  }

  Future<void> closeWatchStreams() =>
      Future.wait(_controllers.map((controller) => controller.close()));
}

class _CountingRegistry extends MediaRegistry {
  _CountingRegistry(super.db);

  var getVideoByIdCalls = 0;

  @override
  Future<VideoRow?> getVideoById(String id) async {
    getVideoByIdCalls++;
    return null;
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
  });

  group('transcriptLinesForMediaProvider autoDispose (issue #810 C2)', () {
    test(
      'cancels the repository watch when the last listener detaches',
      () async {
        final repo = _WatchSpyRepo(db);
        final container = ProviderContainer(
          overrides: [transcriptRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        addTearDown(repo.closeWatchStreams);

        final sub = container.listen(
          transcriptLinesForMediaProvider(_mediaId),
          (_, _) {},
        );
        final lines = await container.read(
          transcriptLinesForMediaProvider(_mediaId).future,
        );
        expect(lines, _lines);
        expect(repo.primaryCancels, isEmpty);

        sub.close();
        await pumpEventQueue();

        expect(repo.primaryCancels, [_mediaId]);
      },
    );

    test(
      're-watching rebuilds the provider against the surviving repository',
      () async {
        final repo = _WatchSpyRepo(db);
        final container = ProviderContainer(
          overrides: [transcriptRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        addTearDown(repo.closeWatchStreams);

        final first = container.listen(
          transcriptLinesForMediaProvider(_mediaId),
          (_, _) {},
        );
        await container.read(transcriptLinesForMediaProvider(_mediaId).future);
        first.close();
        await pumpEventQueue();
        expect(repo.primaryWatches, hasLength(1));

        final second = container.listen(
          transcriptLinesForMediaProvider(_mediaId),
          (_, _) {},
        );
        final lines = await container.read(
          transcriptLinesForMediaProvider(_mediaId).future,
        );
        expect(lines, _lines);
        expect(repo.primaryWatches, hasLength(2));
        second.close();
      },
    );

    test(
      'a watched media keeps its watch while another media is disposed',
      () async {
        final repo = _WatchSpyRepo(db);
        final container = ProviderContainer(
          overrides: [transcriptRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        addTearDown(repo.closeWatchStreams);

        final kept = container.listen(
          transcriptLinesForMediaProvider(_mediaId),
          (_, _) {},
        );
        final dropped = container.listen(
          transcriptLinesForMediaProvider(_otherMediaId),
          (_, _) {},
        );
        await container.read(
          transcriptLinesForMediaProvider(_otherMediaId).future,
        );

        dropped.close();
        await pumpEventQueue();

        expect(repo.primaryCancels, [_otherMediaId]);
        expect(
          repo.primaryWatches,
          containsAll(<String>[_mediaId, _otherMediaId]),
        );
        kept.close();
      },
    );
  });

  group(
    'secondaryTranscriptLinesForMediaProvider autoDispose (issue #810 C2)',
    () {
      test(
        'cancels the repository watch when the last listener detaches',
        () async {
          final repo = _WatchSpyRepo(db);
          final container = ProviderContainer(
            overrides: [transcriptRepositoryProvider.overrideWithValue(repo)],
          );
          addTearDown(container.dispose);
          addTearDown(repo.closeWatchStreams);

          final sub = container.listen(
            secondaryTranscriptLinesForMediaProvider(_mediaId),
            (_, _) {},
          );
          final lines = await container.read(
            secondaryTranscriptLinesForMediaProvider(_mediaId).future,
          );
          expect(lines, _lines);
          expect(repo.secondaryCancels, isEmpty);

          sub.close();
          await pumpEventQueue();

          expect(repo.secondaryCancels, [_mediaId]);
        },
      );
    },
  );

  group('videoRowForMediaProvider autoDispose (issue #810 C2)', () {
    test(
      'disposes with its last listener and re-runs the lookup on re-watch',
      () async {
        final registry = _CountingRegistry(db);
        final container = ProviderContainer(
          overrides: [mediaRegistryProvider.overrideWithValue(registry)],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          videoRowForMediaProvider(_mediaId),
          (_, _) {},
        );
        await container.read(videoRowForMediaProvider(_mediaId).future);
        expect(registry.getVideoByIdCalls, 1);

        sub.close();
        await pumpEventQueue();
        expect(registry.getVideoByIdCalls, 1);

        final second = container.listen(
          videoRowForMediaProvider(_mediaId),
          (_, _) {},
        );
        await container.read(videoRowForMediaProvider(_mediaId).future);
        expect(registry.getVideoByIdCalls, 2);
        second.close();
      },
    );
  });
}
