import 'dart:async';
import 'dart:io' show Platform;

import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/presentation/widgets/media_kit_video_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart'
    show PlatformVideoController, Video, VideoController;

/// Counts reads of [MediaKitPlayerEngine.videoController] and answers with a
/// stub instead of allocating a real controller — a real one spawns
/// media_kit's native machinery, which cannot run inside the FakeAsync
/// widget-test binding. The counter pins "nothing reads the controller while
/// the gate is closed" (the #658 stage-only rule), and the returned stub lets
/// the armed rebuild mount a real [Video] widget on top of the placeholder
/// branch.
class _GateProbeEngine extends MediaKitPlayerEngine {
  int videoControllerReads = 0;

  @override
  VideoController get videoController {
    videoControllerReads++;
    return _StubVideoController();
  }
}

/// Stub [VideoController]: `id`/`rect`/`notifier` stay null so [Video]
/// renders its placeholder; `player` answers only the members [Video]'s
/// state subscriptions touch. Every other member is unreachable in this
/// test and answered loudly by [noSuchMethod].
class _StubVideoController implements VideoController {
  @override
  final ValueNotifier<int?> id = ValueNotifier<int?>(null);

  @override
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  @override
  final ValueNotifier<PlatformVideoController?> notifier =
      ValueNotifier<PlatformVideoController?>(null);

  @override
  final mk.Player player = _StubPlayer();

  @override
  Future<void> get waitUntilFirstFrameRendered => Completer<void>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stub [mk.Player] for [_StubVideoController]: real `state`/`stream` values
/// so [Video]'s initState subscriptions attach to completed streams instead
/// of touching native code.
class _StubPlayer implements mk.Player {
  @override
  final mk.PlayerState state = const mk.PlayerState();

  @override
  final mk.PlayerStream stream = const mk.PlayerStream(
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
    Stream.empty(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MediaKitPlayerEngine on Linux', () {
    test('can be instantiated on Linux without throwing', () {
      final engine = MediaKitPlayerEngine();
      expect(engine, isNotNull);
    });

    test('warmVideoSurface does not throw on Linux', () {
      final engine = MediaKitPlayerEngine();
      expect(() => engine.warmVideoSurface(), returnsNormally);
    }, skip: !Platform.isLinux);

    test(
      'supportsVideoPosterCapture is true on Linux (same as other desks)',
      () {
        final engine = MediaKitPlayerEngine();
        expect(
          engine.supportsVideoPosterCapture,
          true,
          reason: 'media_kit screenshot works on Linux (libmpv frame capture).',
        );
      },
    );

    test('nativeBackendAllowedListenable fires when prepareNativeBackend arms '
        'the gate (issue #751)', () {
      final engine = MediaKitPlayerEngine();
      var fired = 0;
      engine.nativeBackendAllowedListenable.addListener(() => fired++);

      expect(engine.nativeBackendAllowed, isFalse);
      expect(fired, 0);

      engine.prepareNativeBackend();
      expect(engine.nativeBackendAllowed, isTrue);
      expect(fired, 1, reason: 'one notification per arm');
    });

    testWidgets(
      'native backend gate lives in the video stage only (issue #658)',
      (tester) async {
        final engine = _GateProbeEngine();

        Future<void> pumpStage() => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaKitVideoStage(
                engine: engine,
                maxWidth: 320,
                maxHeight: 180,
              ),
            ),
          ),
        );

        expect(engine.nativeBackendAllowed, isFalse);
        await pumpStage();
        expect(find.byType(Video), findsNothing);
        expect(engine.videoControllerReads, 0);
        expect(tester.takeException(), isNull);

        engine.warmVideoSurface();
        expect(engine.nativeBackendAllowed, isFalse);
        await pumpStage();
        expect(find.byType(Video), findsNothing);
        expect(engine.videoControllerReads, 0);
        expect(tester.takeException(), isNull);

        engine.prepareNativeBackend();
        expect(engine.nativeBackendAllowed, isTrue);
        await tester.pump();
        expect(
          engine.videoControllerReads,
          1,
          reason: 'exactly one read: the armed branch building the stage',
        );
        expect(find.byType(Video), findsOneWidget);
        expect(tester.takeException(), isNull);

        await engine.dispose();
      },
    );
  });
}
