import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubeWebViewSettings.forPlayer()', () {
    final s = YoutubeWebViewSettings.forPlayer();

    test('enables JS, inline media playback, and picture-in-picture rules', () {
      expect(s.javaScriptEnabled, isTrue);
      expect(s.allowsInlineMediaPlayback, isTrue);
      expect(s.mediaPlaybackRequiresUserGesture, isFalse);
    });

    test('uses the mobile Chrome user-agent (rejected by default UA)', () {
      expect(s.userAgent, kYoutubeMobileChromeUserAgent);
    });

    test('enables shouldOverrideUrlLoading for ADR-0025 nav interception', () {
      expect(s.useShouldOverrideUrlLoading, isTrue);
    });

    test('sets transparentBackground for overlay layouts', () {
      expect(s.transparentBackground, isTrue);
    });

    test('uses wide-viewport + overview-mode for the YouTube mobile shell', () {
      expect(s.useWideViewPort, isTrue);
      expect(s.loadWithOverviewMode, isTrue);
    });

    test('enables third-party cookies for auth-cookie continuity', () {
      expect(s.thirdPartyCookiesEnabled, isTrue);
    });

    test('disables picture-in-picture on iOS, allows it elsewhere', () {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        expect(s.allowsPictureInPictureMediaPlayback, isFalse);
      } else {
        expect(s.allowsPictureInPictureMediaPlayback, isNull);
      }
    });

    test('subscribes to onRenderProcessGone only on Android', () {
      if (defaultTargetPlatform == TargetPlatform.android) {
        expect(s.useOnRenderProcessGone, isTrue);
      } else {
        expect(s.useOnRenderProcessGone, isNull);
      }
    });
  });

  group('YoutubeWebViewSettings.forLogin()', () {
    final s = YoutubeWebViewSettings.forLogin();

    test('enables JS and third-party cookies', () {
      expect(s.javaScriptEnabled, isTrue);
      expect(s.thirdPartyCookiesEnabled, isTrue);
    });

    test('uses the same mobile Chrome user-agent as the player', () {
      expect(s.userAgent, kYoutubeMobileChromeUserAgent);
    });

    test('enables shouldOverrideUrlLoading for OAuth redirects', () {
      expect(s.useShouldOverrideUrlLoading, isTrue);
    });
  });

  group('YoutubeWebViewBridge JS scripts', () {
    test('pause() script uses __enjoyYtPlayAttempt counter', () {
      expect(YoutubeWebViewBridge.playScript, contains('__enjoyYtPlayAttempt'));
    });

    test('playScript includes the playRejected channel name', () {
      expect(YoutubeWebViewBridge.playScript, contains('playRejected'));
    });

    test('forceInlinePlayback mentions playsinline', () {
      expect(YoutubeWebViewBridge.playScript, contains("'onVideoEvent'"));
    });
  });

  group('YoutubeWebViewBridge URIs', () {
    test('idleUri is about:blank', () {
      expect(YoutubeWebViewBridge.idleUri, isA<WebUri>());
      expect(YoutubeWebViewBridge.idleUri.toString(), 'about:blank');
    });

    test('watchUri uses m.youtube.com', () {
      final uri = YoutubeWebViewBridge.watchUri('abc');
      expect(uri.scheme, 'https');
      expect(uri.host, 'm.youtube.com');
      expect(uri.path, '/watch');
      expect(uri.queryParameters['v'], 'abc');
    });
  });
}
