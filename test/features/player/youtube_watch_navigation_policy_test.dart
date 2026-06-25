import 'package:enjoy_player/features/player/application/engines/youtube/youtube_watch_navigation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isYoutubeWatchPageLoadStopUrl', () {
    test('accepts mobile watch URLs', () {
      expect(
        isYoutubeWatchPageLoadStopUrl(
          'https://m.youtube.com/watch?v=mA1lnxfqHk8',
        ),
        isTrue,
      );
    });

    test('rejects about blank and Google account URLs', () {
      expect(isYoutubeWatchPageLoadStopUrl('about:blank'), isFalse);
      expect(
        isYoutubeWatchPageLoadStopUrl(
          'https://accounts.google.com/ServiceLogin',
        ),
        isFalse,
      );
    });

    test('rejects consent interstitial', () {
      expect(
        isYoutubeWatchPageLoadStopUrl(
          'https://consent.youtube.com/m?continue=...',
        ),
        isFalse,
      );
    });
  });

  group('resolveYoutubeNavigationIsForMainFrame', () {
    test('null is treated as subframe (allow CDN)', () {
      expect(resolveYoutubeNavigationIsForMainFrame(null), isFalse);
    });
  });

  group('isPassiveGoogleSignInUrl', () {
    test('detects passive ServiceLogin', () {
      const url =
          'https://accounts.google.com/ServiceLogin?passive=true&'
          'continue=https%3A%2F%2Fm.youtube.com%2Fsignin_passive';
      expect(isPassiveGoogleSignInUrl(url), isTrue);
    });

    test('detects signin_passive in continue URL', () {
      const url =
          'https://accounts.google.com/v3/signin/identifier?'
          'continue=https%3A%2F%2Fm.youtube.com%2Fsignin%3Fsignin_passive';
      expect(isPassiveGoogleSignInUrl(url), isTrue);
    });

    test('returns false for non-Google URLs', () {
      expect(
        isPassiveGoogleSignInUrl('https://m.youtube.com/watch?v=abc12345678'),
        isFalse,
      );
    });
  });

  group('isYoutubePlaybackOrStaticAssetUrl', () {
    test('detects googlevideo CDN', () {
      expect(
        isYoutubePlaybackOrStaticAssetUrl(
          'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1',
        ),
        isTrue,
      );
    });
  });

  group('shouldAllowYoutubeWatchNavigation', () {
    const videoId = 'mA1lnxfqHk8';

    test('allows about:blank', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'about:blank',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
    });

    test('allows mobile watch and YouTube redirects', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://m.youtube.com/watch?v=$videoId',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://www.youtube.com/watch?v=$videoId',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://m.youtube.com/',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
    });

    test('blocks Google account navigations during playback', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url:
              'https://accounts.google.com/ServiceLogin?passive=true&'
              'service=youtube',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isFalse,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://accounts.google.com/v3/signin/identifier',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isFalse,
      );
    });

    test('allows consent and static Google assets', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://consent.youtube.com/m?continue=...',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://fonts.gstatic.com/s/roboto/v1/foo.woff2',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
    });

    test('allows googlevideo CDN on main frame', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://rr3---sn-abc.googlevideo.com/videoplayback?expire=1',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isTrue,
      );
    });

    test('allows all subresource loads regardless of origin', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://example.com/segment.ts',
          videoId: videoId,
          isForMainFrame: false,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://accounts.google.com/ServiceLogin?passive=true',
          videoId: videoId,
          isForMainFrame: false,
        ),
        isTrue,
      );
    });

    test('denies unrelated main-frame origins when a video is open', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://example.com/',
          videoId: videoId,
          isForMainFrame: true,
        ),
        isFalse,
      );
    });

    test('denies watch URLs when video id is empty (idle WebView)', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://m.youtube.com/watch?v=$videoId',
          videoId: '',
          isForMainFrame: true,
        ),
        isFalse,
      );
    });
  });
}
