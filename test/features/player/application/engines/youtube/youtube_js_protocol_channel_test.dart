import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scripted_js_channel.dart';

/// Records the most recent poll callback invocation so tests can assert on
/// the decoded (position, duration, paused, ended) tuple.
class _RecordingCallback {
  Duration? position;
  Duration? newDuration;
  bool? jsPaused;
  bool? jsEnded;
  int invocations = 0;

  void call({
    required Duration position,
    Duration? newDuration,
    required bool jsPaused,
    required bool jsEnded,
  }) {
    this.position = position;
    this.newDuration = newDuration;
    this.jsPaused = jsPaused;
    this.jsEnded = jsEnded;
    invocations++;
  }
}

void main() {
  group('YoutubeWebViewBridge.poll (executed over the scripted channel)', () {
    test('is a no-op when disposed is true', () async {
      final cb = _RecordingCallback();
      await YoutubeWebViewBridge.poll(
        disposed: true,
        channel: null,
        onResult: cb.call,
      );
      expect(cb.invocations, 0);
    });

    test('is a no-op when the channel is null', () async {
      final cb = _RecordingCallback();
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: null,
        onResult: cb.call,
      );
      expect(cb.invocations, 0);
    });

    test('decodes a playing sample (state=1) and forwards duration', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(
        results: ['{"t":12.5,"d":120.0,"s":1}'],
      );
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 1);
      expect(cb.position, const Duration(milliseconds: 12500));
      expect(cb.newDuration, const Duration(milliseconds: 120000));
      expect(cb.jsPaused, isFalse);
      expect(cb.jsEnded, isFalse);
    });

    test('decodes a paused sample (state=0)', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(results: ['{"t":5.25,"d":60.0,"s":0}']);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 1);
      expect(cb.position, const Duration(milliseconds: 5250));
      expect(cb.jsPaused, isTrue);
      expect(cb.jsEnded, isFalse);
    });

    test('decodes an ended sample (state=2)', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(results: ['{"t":0,"d":60.0,"s":2}']);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 1);
      expect(cb.jsPaused, isFalse);
      expect(cb.jsEnded, isTrue);
    });

    test('leaves newDuration null when d=0', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(results: ['{"t":1.0,"d":0,"s":1}']);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 1);
      expect(cb.newDuration, isNull);
    });

    test('ignores a null evaluate result', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel();
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 0);
    });

    test('ignores invalid JSON', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(results: ['not json']);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 0);
    });

    test('ignores a non-object JSON result', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(results: ['[1,2,3]']);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 0);
    });

    test('ignores a non-finite duration string', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(results: ['{"t":1.0,"d":1e999,"s":1}']);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      // 1e999 parses to double.infinity — `isFinite` gate drops it, but the
      // sample itself still reports position.
      expect(cb.invocations, 1);
      expect(cb.newDuration, isNull);
    });

    test('swallows an evaluate error (WebView mid-teardown)', () async {
      final cb = _RecordingCallback();
      final channel = ScriptedJsChannel(throwOnEvaluate: true);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult: cb.call,
      );
      expect(cb.invocations, 0);
    });

    test('evaluates the poll script with the shared video locator', () async {
      final channel = ScriptedJsChannel(results: [null]);
      await YoutubeWebViewBridge.poll(
        disposed: false,
        channel: channel,
        onResult:
            ({
              required Duration position,
              Duration? newDuration,
              required bool jsPaused,
              required bool jsEnded,
            }) {},
      );
      expect(channel.evaluatedSources, hasLength(1));
      expect(channel.evaluatedSources.single, contains('.html5-video-player'));
      // One spelling: the poll script embeds the bridge's locator verbatim.
      expect(
        channel.evaluatedSources.single,
        contains(YoutubeWebViewBridge.locateVideo),
      );
    });
  });

  group('decodePollSample', () {
    test('maps the s encoding: 0 paused / 1 playing / 2 ended', () {
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":0}')!.paused,
        isTrue,
      );
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":1}')!.paused,
        isFalse,
      );
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":1}')!.ended,
        isFalse,
      );
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":2}')!.ended,
        isTrue,
      );
    });

    test('shape drift decodes to null, never to a default state', () {
      // A missing/mistyped key must not read as "playing at t=0" — that is
      // the false-positive the poll loop cannot distinguish from DOM truth
      // (issue #767 review). Every drift below drops the tick instead.
      expect(YoutubeWebViewBridge.decodePollSample('{"d":2,"s":1}'), isNull);
      expect(YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2}'), isNull);
      // Missing `d` is NOT drift: the page sends 0 for "no duration yet",
      // so absence decodes as (position, null duration) — the lenient key.
      expect(YoutubeWebViewBridge.decodePollSample('{"t":1,"s":1}'), (
        position: const Duration(seconds: 1),
        duration: null,
        paused: false,
        ended: false,
      ));
      // A mistyped `d` is lenient like a missing one: it reads as zero
      // (null duration) instead of throwing — only `t` / `s` are strict.
      expect(YoutubeWebViewBridge.decodePollSample('{"t":1,"d":"2","s":1}'), (
        position: const Duration(seconds: 1),
        duration: null,
        paused: false,
        ended: false,
      ));
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":null}'),
        isNull,
      );
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":"0"}'),
        isNull,
      );
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":"1","d":2,"s":1}'),
        isNull,
      );
      // Out-of-contract state code: the JS only emits 0/1/2.
      expect(
        YoutubeWebViewBridge.decodePollSample('{"t":1,"d":2,"s":9}'),
        isNull,
      );
    });

    test('returns null for null / malformed / non-object input', () {
      expect(YoutubeWebViewBridge.decodePollSample(null), isNull);
      expect(YoutubeWebViewBridge.decodePollSample('oops'), isNull);
      expect(YoutubeWebViewBridge.decodePollSample('[1]'), isNull);
      expect(YoutubeWebViewBridge.decodePollSample(42), isNull);
    });
  });

  group('playOrPause decode (D9 contract, executed)', () {
    test('decodes the DOM-decided direction strings', () async {
      for (final (direction, expected) in [
        ('play', 'play'),
        ('pause', 'pause'),
      ]) {
        final channel = ScriptedJsChannel(results: [direction]);
        expect(
          await YoutubeWebViewBridge.playOrPause(channel),
          expected,
          reason: 'direction $direction must decode verbatim',
        );
      }
    });

    test('non-string and null results decode to null', () async {
      expect(
        await YoutubeWebViewBridge.playOrPause(ScriptedJsChannel()),
        isNull,
      );
      expect(
        await YoutubeWebViewBridge.playOrPause(ScriptedJsChannel(results: [7])),
        isNull,
      );
    });

    test('a missing channel decodes to null', () async {
      expect(await YoutubeWebViewBridge.playOrPause(null), isNull);
    });
  });

  group('script dispatch over the channel', () {
    test('transport scripts evaluate exactly their protocol source', () async {
      final channel = ScriptedJsChannel();
      await YoutubeWebViewBridge.play(channel);
      await YoutubeWebViewBridge.pause(channel);
      await YoutubeWebViewBridge.stop(channel);
      await YoutubeWebViewBridge.refocusWindow(channel);
      await YoutubeWebViewBridge.playWhenReady(channel);
      await YoutubeWebViewBridge.forceInlinePlayback(channel);
      expect(channel.evaluatedSources.sublist(0, 5), [
        YoutubeWebViewBridge.playScript,
        YoutubeWebViewBridge.pauseScript,
        YoutubeWebViewBridge.stopScript,
        YoutubeWebViewBridge.focusWindowScript,
        YoutubeWebViewBridge.playWhenReadyScript,
      ]);
      expect(channel.evaluatedSources.last, contains('playsinline'));
    });

    test('seek interpolates seconds; rate interpolates speed', () async {
      final channel = ScriptedJsChannel();
      await YoutubeWebViewBridge.seekToSeconds(channel, 12.5);
      await YoutubeWebViewBridge.setPlaybackRate(channel, 1.75);
      expect(channel.evaluatedSources.first, contains('v.currentTime=12.5'));
      expect(channel.evaluatedSources.last, contains('v.playbackRate=1.75'));
    });

    test('volume interpolation formats as a plain double', () async {
      final channel = ScriptedJsChannel();
      await YoutubeWebViewBridge.setVolume(channel, 0.5);
      expect(channel.evaluatedSources.single, contains('var vol=0.5;'));
    });

    test('loadWatchPage / loadIdlePage navigate via loadUri', () async {
      final channel = ScriptedJsChannel();
      await YoutubeWebViewBridge.loadWatchPage(channel, 'abc-_123');
      await YoutubeWebViewBridge.loadIdlePage(channel);
      expect(channel.loadedUris.map((u) => u.toString()).toList(), [
        'https://m.youtube.com/watch?v=abc-_123',
        'about:blank',
      ]);
    });

    test('null channel never evaluates', () async {
      await YoutubeWebViewBridge.play(null);
      await YoutubeWebViewBridge.pause(null);
      await YoutubeWebViewBridge.stop(null);
      await YoutubeWebViewBridge.playWhenReady(null);
      await YoutubeWebViewBridge.refocusWindow(null);
      await YoutubeWebViewBridge.forceInlinePlayback(null);
      await YoutubeWebViewBridge.loadIdlePage(null);
      await YoutubeWebViewBridge.loadWatchPage(null, 'x');
      await YoutubeWebViewBridge.setVolume(null, 0.5);
      await YoutubeWebViewBridge.setPlaybackRate(null, 1.0);
      await YoutubeWebViewBridge.seekToSeconds(null, 1);
    });

    test('every playback-mutating script carries the stale-attempt guard', () {
      // The __enjoyYtPlayAttempt protocol: any newer transport command
      // supersedes an in-flight play's rejection callback. A script that
      // starts or stops playback without bumping the counter can surface a
      // stale rejection after a pause already won.
      for (final script in [
        YoutubeWebViewBridge.playScript,
        YoutubeWebViewBridge.playOrPauseScript,
        YoutubeWebViewBridge.pauseScript,
        YoutubeWebViewBridge.stopScript,
        YoutubeWebViewBridge.playWhenReadyScript,
      ]) {
        expect(
          script,
          contains('__enjoyYtPlayAttempt'),
          reason:
              'playback-mutating script must participate in the '
              'stale-attempt guard protocol',
        );
      }
    });
  });
}
