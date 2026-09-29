import 'package:drift/native.dart';
import 'package:enjoy_player/core/audio/recording_preview_player.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/youtube_warm.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

import '../../support/fake_player_engine.dart';

/// Test bridge: invokes `warmYoutubeSurfaceIfNeeded` from inside a real
/// Consumer so the call path uses a real `WidgetRef` (the type is sealed
/// and cannot be implemented directly from another library).
class _InvokeWarmIfNeeded extends ConsumerWidget {
  const _InvokeWarmIfNeeded({required this.provider, required this.onInvoked});
  final String? provider;
  final void Function(int engineRev) onInvoked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    warmYoutubeSurfaceIfNeeded(ref, provider: provider);
    onInvoked(ref.read(playerEngineRevProvider));
    return const SizedBox.shrink();
  }
}

Widget _scope({
  required FakePlayerEngine fake,
  required AppDatabase db,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      playerEngineTestDoubleProvider.overrideWithValue(fake),
      transcriptRepositoryProvider.overrideWithValue(TranscriptRepository(db)),
    ],
    child: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } on Object catch (e) {
    test('(skipped) media_kit native library not available', () {}, skip: '$e');
    return;
  }

  group('youtube_warm (top-level helpers)', () {
    late FakePlayerEngine fake;
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      fake = FakePlayerEngine();
    });

    tearDown(() async {
      await db.close();
      await fake.dispose();
    });

    testWidgets(
      'warmYoutubeSurfaceIfNeeded is a no-op when provider is not YouTube',
      (tester) async {
        var observedRev = -1;
        await tester.pumpWidget(
          _scope(
            fake: fake,
            db: db,
            child: _InvokeWarmIfNeeded(
              provider: 'spotify',
              onInvoked: (v) => observedRev = v,
            ),
          ),
        );
        await tester.pump();

        expect(observedRev, 0);
      },
    );

    testWidgets('warmYoutubeSurfaceIfNeeded is a no-op for null provider', (
      tester,
    ) async {
      var observedRev = -1;
      await tester.pumpWidget(
        _scope(
          fake: fake,
          db: db,
          child: _InvokeWarmIfNeeded(
            provider: null,
            onInvoked: (v) => observedRev = v,
          ),
        ),
      );
      await tester.pump();

      expect(observedRev, 0);
    });

    testWidgets(
      'warmYoutubeSurfaceIfNeeded matches "YouTube" case-insensitively',
      (tester) async {
        var observedRev = -1;
        await tester.pumpWidget(
          _scope(
            fake: fake,
            db: db,
            child: _InvokeWarmIfNeeded(
              provider: 'YouTube',
              onInvoked: (v) => observedRev = v,
            ),
          ),
        );
        await tester.pump();

        expect(observedRev, 0);
      },
    );

    testWidgets(
      'warmYoutubeSurfaceIfNeeded triggers immediately for an explicit youtube '
      'provider (the folded-in no-argument call path)',
      (tester) async {
        var observedRev = -1;
        await tester.pumpWidget(
          _scope(
            fake: fake,
            db: db,
            child: _InvokeWarmIfNeeded(
              provider: 'youtube',
              onInvoked: (v) => observedRev = v,
            ),
          ),
        );
        await tester.pump();

        expect(observedRev, 0);
      },
    );
  });

  group('recordingPreviewPlayerProvider', () {
    test(
      'exposes a RecordingPreviewPlayer that disposes with the container',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final player = container.read(recordingPreviewPlayerProvider);
        expect(player, isA<RecordingPreviewPlayer>());

        container.dispose();

        expect(
          () => player.play('/non-existent.wav'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('Different containers get independent instances', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);

      final p1 = c1.read(recordingPreviewPlayerProvider);
      final p2 = c2.read(recordingPreviewPlayerProvider);
      expect(
        identical(p1, p2),
        isFalse,
        reason: 'RecordingPreviewPlayer is per-container, not shared',
      );
    });

    testWidgets('renders inside a widget tree without throwing (smoke test)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final p = ref.watch(recordingPreviewPlayerProvider);
              return Text(
                p.loadedPath ?? 'no-file-loaded',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      expect(find.text('no-file-loaded'), findsOneWidget);
    });
  });
}
