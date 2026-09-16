import 'package:enjoy_player/features/player/application/engines/youtube/youtube_session.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_poll_loop.dart';
import 'package:flutter_test/flutter_test.dart';

/// attachWebView replacement contract for [YoutubeSession] (issue #721).
///
/// The doc contract invites re-attachment ("tests may swap fakes"), so a
/// replaced poll loop must be stopped, not orphaned mid-cadence polling the
/// stale controller forever.
void main() {
  group('attachWebView', () {
    test('replacing the attachment stops the previous poll loop', () {
      YoutubeSessionWebAttachment attachment() => YoutubeSessionWebAttachment(
        webController: () => null,
        onFirstPlaying: () {},
        reapplyVolume: () async {},
        healPlay: () async {},
      );

      final session = YoutubeSession()..resetForOpen('abc12345678');
      YoutubeWebViewPollLoop? latest;
      addTearDown(() => latest?.stop());

      session.attachWebView(attachment());
      latest = session.pollLoop;
      latest.start();
      expect(latest.isRunning, isTrue);

      session.attachWebView(attachment());
      final second = session.pollLoop;
      expect(identical(latest, second), isFalse);
      expect(
        latest.isRunning,
        isFalse,
        reason:
            'a replaced poll loop must be stopped, not left re-arming '
            'itself against the stale attachment',
      );
    });
  });
}
