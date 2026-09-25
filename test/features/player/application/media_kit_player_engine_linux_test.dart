import 'dart:io' show Platform;

import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/presentation/widgets/media_kit_video_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit_video/media_kit_video.dart'
    show Video, VideoController;

/// Counts reads of [MediaKitPlayerEngine.videoController] instead of
/// allocating a real one: the allowed branch reads the getter before
/// mounting [Video], so the counter proves the stage entered the
/// Video-mounting branch without touching media_kit's native machinery
/// (a real `Player` cannot run inside the FakeAsync widget-test binding).
class _GateProbeEngine extends MediaKitPlayerEngine {
  int videoControllerReads = 0;

  @override
  VideoController get videoController {
    videoControllerReads++;
    throw UnimplementedError('probe: the Video branch must not allocate');
  }
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
      // The mounted stage listens to this instead of a hand-bumped
      // playerEngineRevProvider: the rev now signals identity changes only,
      // so arming the backend must notify through the engine itself.
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

        // Not allowed yet: a bare placeholder — the video controller is not
        // even read, hence no mpv allocation.
        expect(engine.nativeBackendAllowed, isFalse);
        await pumpStage();
        expect(find.byType(Video), findsNothing);
        expect(engine.videoControllerReads, 0);

        // Engine entry points other than [prepareNativeBackend] must not
        // approve the gate. The old `_player` getter did exactly that (it set
        // `_nativeBackendAllowed = true` while claiming to check it), so the
        // gate is stage-only and nothing else can flip it.
        engine.warmVideoSurface();
        expect(engine.nativeBackendAllowed, isFalse);
        await pumpStage();
        expect(find.byType(Video), findsNothing);
        expect(engine.videoControllerReads, 0);

        // Arming the gate while the placeholder is already mounted must
        // rebuild through the stage's own listener and enter the
        // Video-mounting branch — the signal that used to ride a second
        // hand-bumped playerEngineRev (issue #751). Without this path a
        // YouTube→MediaKit swap would show a black placeholder forever.
        engine.prepareNativeBackend();
        expect(engine.nativeBackendAllowed, isTrue);
        await tester.pump();
        expect(
          engine.videoControllerReads,
          1,
          reason:
              'the mounted placeholder must rebuild into the Video branch '
              'when the gate arms (the probe getter throws there)',
        );
        expect(tester.takeException(), isUnimplementedError);
      },
    );
  });
}
