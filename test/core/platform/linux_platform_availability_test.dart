import 'package:enjoy_player/core/platform/linux_platform_availability.dart'
    as linux_avail;
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveYouTubeAvailability (specs/047)', () {
    setUp(linux_avail.debugResetYouTubeAvailability);
    tearDown(() {
      linux_avail.debugYouTubeAvailabilityProbe = null;
      debugDefaultTargetPlatformOverride = null;
      linux_avail.debugResetYouTubeAvailability();
    });

    test('kill switch defaults off (rollback posture stays dormant)', () {
      expect(linux_avail.youtubeEngineKillSwitchOn, isFalse);
    });

    test(
      'short-circuits to available on non-Linux targets without probing',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        var probes = 0;
        linux_avail.debugYouTubeAvailabilityProbe = () async {
          probes++;
          return const linux_avail.YouTubeUnavailable(
            linux_avail.YouTubeUnavailableReason.runtimeMissing,
          );
        };

        final decision = await linux_avail.resolveYouTubeAvailability();

        expect(decision.canPlay, isTrue);
        expect(probes, 0);
        expect(linux_avail.resolvedYouTubeAvailability, isNull);
      },
    );

    test(
      'resolves once per process — concurrent callers share one probe',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        var probes = 0;
        linux_avail.debugYouTubeAvailabilityProbe = () async {
          probes++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return const linux_avail.YouTubeAvailable();
        };

        final decisions = await Future.wait([
          linux_avail.resolveYouTubeAvailability(),
          linux_avail.resolveYouTubeAvailability(),
          linux_avail.resolveYouTubeAvailability(),
        ]);

        expect(probes, 1);
        expect(decisions.every((d) => d.canPlay), isTrue);
        expect(linux_avail.resolvedYouTubeAvailability?.canPlay, isTrue);
      },
    );

    test(
      'failed probe resolves to unavailable, never throws (contract A3)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        linux_avail.debugYouTubeAvailabilityProbe = () async {
          throw StateError('runtime exploded');
        };

        final decision = await linux_avail.resolveYouTubeAvailability();

        expect(decision.canPlay, isFalse);
        final unavailable = decision as linux_avail.YouTubeUnavailable;
        expect(
          unavailable.reason,
          linux_avail.YouTubeUnavailableReason.runtimeInitFailed,
        );
      },
    );

    test('resolution is cached — later calls reuse the probe result', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      var probes = 0;
      linux_avail.debugYouTubeAvailabilityProbe = () async {
        probes++;
        return const linux_avail.YouTubeUnavailable(
          linux_avail.YouTubeUnavailableReason.runtimeMissing,
        );
      };

      await linux_avail.resolveYouTubeAvailability();
      final second = await linux_avail.resolveYouTubeAvailability();

      expect(probes, 1);
      expect(second.canPlay, isFalse);
    });

    test('debugResetYouTubeAvailability clears the cached decision', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      var probes = 0;
      linux_avail.debugYouTubeAvailabilityProbe = () async {
        probes++;
        return const linux_avail.YouTubeAvailable();
      };

      await linux_avail.resolveYouTubeAvailability();
      linux_avail.debugResetYouTubeAvailability();
      await linux_avail.resolveYouTubeAvailability();

      expect(probes, 2);
    });
  });

  test('googleSignInAvailableOnLinux is false (disabled per ADR-0084)', () {
    expect(
      linux_avail.googleSignInAvailableOnLinux,
      false,
      reason:
          'google_sign_in browser-based OAuth fails on real Linux installs. '
          'Linux uses email OTP + web PKCE fallback (ADR-0084).',
    );
  });
}
