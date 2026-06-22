import 'package:enjoy_player/features/player/application/engines/youtube/youtube_watch_navigation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('shouldAllowYoutubeWatchNavigation', () {
    const videoId = 'mA1lnxfqHk8';

    test('allows about:blank', () {
      expect(
        shouldAllowYoutubeWatchNavigation(url: 'about:blank', videoId: videoId),
        isTrue,
      );
    });

    test('allows mobile watch and YouTube redirects', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://m.youtube.com/watch?v=$videoId',
          videoId: videoId,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://www.youtube.com/watch?v=$videoId',
          videoId: videoId,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://m.youtube.com/',
          videoId: videoId,
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
        ),
        isFalse,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://accounts.google.com/v3/signin/identifier',
          videoId: videoId,
        ),
        isFalse,
      );
    });

    test('allows consent and static Google assets', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://consent.youtube.com/m?continue=...',
          videoId: videoId,
        ),
        isTrue,
      );
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://fonts.gstatic.com/s/roboto/v1/foo.woff2',
          videoId: videoId,
        ),
        isTrue,
      );
    });

    test('denies unrelated origins when a video is open', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://example.com/',
          videoId: videoId,
        ),
        isFalse,
      );
    });

    test('denies watch URLs when video id is empty (idle WebView)', () {
      expect(
        shouldAllowYoutubeWatchNavigation(
          url: 'https://m.youtube.com/watch?v=$videoId',
          videoId: '',
        ),
        isFalse,
      );
    });
  });
}
