/// The YouTube JS protocol: every script Dart evaluates into the watch
/// page, the decode of every value the page hands back, and the URL/UA
/// setup the WebView needs — all behind the app-owned [YoutubeJsChannel]
/// seam (issue #767).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'youtube_js_channel.dart';

/// Shared by player + login WebViews — Google/YouTube reject default WKWebView UAs.
const String kYoutubeMobileChromeUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/134.0.0.0 Mobile Safari/537.36';

/// WebView settings for YouTube player and sign-in (keep UA aligned).
class YoutubeWebViewSettings {
  YoutubeWebViewSettings._();

  /// Shared player settings.
  ///
  /// Cached: the stage re-creates its widget subtree on mount ticks, and a
  /// fresh [InAppWebViewSettings] per build is both garbage and — because it
  /// is passed as `initialSettings` — an unnecessary settings push on the
  /// platform side. Nothing in the app mutates the returned instance, so the
  /// same object is handed to every [InAppWebView] (issue #663).
  static final InAppWebViewSettings _player = InAppWebViewSettings(
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    allowsPictureInPictureMediaPlayback:
        defaultTargetPlatform == TargetPlatform.iOS ? false : null,
    javaScriptEnabled: true,
    transparentBackground: true,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    userAgent: kYoutubeMobileChromeUserAgent,
    thirdPartyCookiesEnabled: true,
    // Required on Android/iOS/macOS/Windows for [shouldOverrideUrlLoading] (ADR-0025).
    useShouldOverrideUrlLoading: true,
    // Android: allow listening for renderer crashes (reload watch page).
    useOnRenderProcessGone: defaultTargetPlatform == TargetPlatform.android
        ? true
        : null,
  );

  /// Identical settings every call — do not mutate the returned instance.
  static InAppWebViewSettings forPlayer() => _player;

  static InAppWebViewSettings forLogin() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      thirdPartyCookiesEnabled: true,
      userAgent: kYoutubeMobileChromeUserAgent,
      useShouldOverrideUrlLoading: true,
    );
  }
}

/// One decoded DOM sample from `YoutubeWebViewBridge.pollScript`.
///
/// `duration` is null when the element reports no finite duration yet.
typedef YoutubePollSample = ({
  Duration position,
  Duration? duration,
  bool paused,
  bool ended,
});

class YoutubeWebViewBridge {
  YoutubeWebViewBridge._();

  static WebUri get idleUri => WebUri('about:blank');

  static WebUri watchUri(String videoId) =>
      WebUri('https://m.youtube.com/watch?v=$videoId');

  /// Locates the `<video>` element inside YouTube's player container.
  ///
  /// The ONE spelling of the video locator shared by every bridge script
  /// and the state poll (issue #767; previously spelled independently in
  /// three places). The watch-page inject keeps its own `mainVideo()`
  /// inside the page script — it runs before this module's scripts exist
  /// as separate concerns on the page side.
  static const String locateVideo = '''
      var p=document.querySelector('.html5-video-player');
      var v=p?p.querySelector('video'):null;
      if(!v) v=document.querySelector('video');
  ''';

  /// Locates the `<video>` element and YouTube's own page player object.
  ///
  /// Transport and volume commands must go through the page player
  /// (`mp.playVideo()` / `mp.unMute()` / …) whenever it is available:
  /// mutating the raw element (especially `video.muted`) behind the page's
  /// back lets its autoplay-policy/state machine re-pause the element shortly
  /// after playback starts — the play-then-pause symptom.
  static const String _findVideoAndPlayer =
      '''
      $locateVideo
      var mp=document.querySelector('#movie_player')||p;
      if(!mp||typeof mp.playVideo!=='function') mp=null;
  ''';

  /// Playback-start body shared by [playScript] and [playOrPauseScript].
  ///
  /// Never muting here is the play-then-pause fix: Chromium gives each media
  /// element a gesture lock that muted starts bypass, and unmuting later
  /// without fresh user activation pauses the element ("Unmuting failed and
  /// the element was paused instead"). Every forced mute here used to be
  /// followed by a programmatic unmute in the volume-restore path, tripping
  /// exactly that rule. Starts must preserve the current audible state; only
  /// the per-document volume restore may flip audibility (see
  /// [YoutubeWebViewEvents]).
  static const String _startPlaybackBody = '''
      var attempt=(window.__enjoyYtPlayAttempt||0)+1;
      window.__enjoyYtPlayAttempt=attempt;
      function rejected(error){
        if(window.__enjoyYtPlayAttempt!==attempt) return;
        var name=error&&error.name?error.name:'UnknownError';
        var message=error&&error.message?error.message:'';
        var bridge=window.flutter_inappwebview;
        if(bridge&&typeof bridge.callHandler==='function'){
          bridge.callHandler(
            'onVideoEvent','playRejected',name+(message?': '+message:''));
        }
      }
      if(mp){
        try{mp.playVideo();}catch(e){}
      } else {
        try{
          var result=v.play();
          if(result&&typeof result.catch==='function') result.catch(rejected);
        }catch(error){rejected(error);}
      }
  ''';

  /// Pause body shared by [pauseScript], [stopScript], and the pause branch
  /// of [playOrPauseScript]. Bumping `__enjoyYtPlayAttempt` invalidates any
  /// in-flight play attempt's rejection callback (see [_startPlaybackBody]),
  /// so a stale play error cannot surface after the pause already won.
  static const String _pauseBody = '''
      window.__enjoyYtPlayAttempt=(window.__enjoyYtPlayAttempt||0)+1;
      if(mp){try{mp.pauseVideo();}catch(e){}}
      else if(v){v.pause();}
  ''';

  static const String playScript =
      '''
    (function(){
      $_findVideoAndPlayer
      if(!v) return;
      $_startPlaybackBody
    })();
  ''';

  /// Atomic toggle based on the live `<video>` element — never trusts Dart
  /// [YoutubeSession.playing], which can lag DOM pauses by hundreds of ms.
  /// State changes are applied through the page player when available.
  ///
  /// Reports the direction the DOM actually took — `'play'` / `'pause'`, or
  /// `null` when no `<video>` was found — so the caller classifies the
  /// toggle's intent from DOM truth, not from stale session state (which
  /// lags the very pause the toggle may be reacting to).
  static const String playOrPauseScript =
      '''
    (function(){
      $_findVideoAndPlayer
      if(!v) return null;
      var paused=v.paused||v.ended;
      if(mp&&typeof mp.isPaused==='function'){
        try{paused=!!mp.isPaused();}catch(e){}
      }
      if(paused){
        $_startPlaybackBody
        return 'play';
      } else {
        $_pauseBody
        return 'pause';
      }
    })();
  ''';

  /// Pause script — routes through the page player when available, falling
  /// back to the raw element (see [_findVideoAndPlayer]).
  static const String pauseScript =
      '''
    (function(){
      $_findVideoAndPlayer
      $_pauseBody
    })();
  ''';

  /// [pauseScript] plus a position reset to the start of the video.
  static const String stopScript =
      '''
    (function(){
      $_findVideoAndPlayer
      $_pauseBody
      if(v){v.currentTime=0;}
    })();
  ''';

  /// Re-asserts the pinned focus state in the watch page (see the focus pin
  /// in the watch inject). Used when the video stage unparks — overlays park
  /// the WebView off-corner (ADR-0066) and Android may clear its view focus,
  /// which m.youtube.com's player treats as "not user-initiated" and answers
  /// by pausing programmatic playback — and before each automatic play retry.
  /// Idempotent; returns the page's (patched) focus reading.
  static const String focusWindowScript = '''
    (function(){
      try{document.hasFocus=function(){return true;};}catch(e){}
      try{window.dispatchEvent(new Event('focus'));}catch(e){}
      try{return document.hasFocus();}catch(e){return null;}
    })();
  ''';

  static Future<void> refocusWindow(YoutubeJsChannel? channel) async {
    await channel?.evaluate(focusWindowScript);
  }

  /// Data-gated play for automatic retries (immediate-pause recovery).
  ///
  /// Field rounds 3–5: the page player pauses the element when playback
  /// outruns the buffer (`ctx pstate=3` — buffering — with decoder input
  /// arriving ~10× slower than realtime on the reporting device). Re-playing
  /// immediately just burns the tiny re-buffered amount and pauses again; the
  /// retry therefore waits (≤ ~5 s, 250 ms steps) until the element has
  /// `readyState ≥ 3` AND ≥ 1 s buffered ahead, then plays. The
  /// `__enjoyYtPlayAttempt` bump keeps this consistent with the stale-guard
  /// protocol: any newer transport command supersedes the waiting retry.
  static const String playWhenReadyScript =
      '''
    (function(){
      $_findVideoAndPlayer
      if(!v) return;
      var attempt=(window.__enjoyYtPlayAttempt||0)+1;
      window.__enjoyYtPlayAttempt=attempt;
      var tries=0;
      function ahead(){
        try{
          for(var i=0;i<v.buffered.length;i++){
            if(v.buffered.start(i)<=v.currentTime&&v.currentTime<v.buffered.end(i)){
              return v.buffered.end(i)-v.currentTime;
            }
          }
        }catch(e){}
        return 0;
      }
      function step(){
        if(window.__enjoyYtPlayAttempt!==attempt) return;
        if(tries++>20) return;
        if(v.readyState>=3&&ahead()>=1){
          try{
            if(mp){mp.playVideo();}
            else{
              var r=v.play();
              if(r&&typeof r.catch==='function') r.catch(function(){});
            }
          }catch(e){}
          return;
        }
        setTimeout(step,250);
      }
      step();
    })();
  ''';

  static Future<void> playWhenReady(YoutubeJsChannel? channel) async {
    await channel?.evaluate(playWhenReadyScript);
  }

  static Future<void> play(YoutubeJsChannel? channel) async {
    await channel?.evaluate(playScript);
  }

  /// Play when the DOM video is paused/ended; pause when it is playing.
  /// Returns the DOM-decided direction (`'play'` / `'pause'`) or `null`
  /// when no video was found (see [playOrPauseScript]).
  static Future<String?> playOrPause(YoutubeJsChannel? channel) async {
    final result = await channel?.evaluate(playOrPauseScript);
    return result is String ? result : null;
  }

  static Future<void> pause(YoutubeJsChannel? channel) async {
    await channel?.evaluate(pauseScript);
  }

  static Future<void> seekToSeconds(
    YoutubeJsChannel? channel,
    double seconds,
  ) async {
    await channel?.evaluate('''
        (function(){
          $_findVideoAndPlayer
          if(v) v.currentTime=$seconds;
        })();
      ''');
  }

  static Future<void> stop(YoutubeJsChannel? channel) async {
    await channel?.evaluate(stopScript);
  }

  static Future<void> setPlaybackRate(
    YoutubeJsChannel? channel,
    double speed,
  ) async {
    await channel?.evaluate('''
        (function(){
          $_findVideoAndPlayer
          if(v) v.playbackRate=$speed;
        })();
      ''');
  }

  /// Volume/mute script. Prefers the page player API (`unMute` / `mute` /
  /// `setVolume` 0-100) so unmute does not fight YouTube's gesture-gated
  /// autoplay policy; element mutation is only the no-API fallback.
  ///
  /// Idempotent: when the element already matches the requested state the
  /// script exits without touching anything. Every skipped `muted=false`
  /// mutation is one fewer chance for Chromium's gesture lock to pause an
  /// autoplaying-muted video ("Unmuting failed and the element was paused").
  static String setVolumeScript(double volume) =>
      '''
        (function(){
          $_findVideoAndPlayer
          var vol=$volume;
          if(v){
            var wantMuted=(vol<=0.001);
            var volDelta=(typeof v.volume==='number')?Math.abs(v.volume-vol):1;
            var stateMatches=wantMuted?(v.muted===true):(v.muted===false&&volDelta<=0.001);
            if(stateMatches) return;
          }
          if(mp){
            try{
              if(vol<=0.001){
                if(typeof mp.mute==='function'){mp.mute();}
                else{mp.setVolume(0);}
              }else{
                if(typeof mp.unMute==='function'){mp.unMute();}
                mp.setVolume(Math.round(vol*100));
              }
            }catch(e){}
            return;
          }
          if(v){v.volume=vol;v.muted=(vol<=0.001);}
        })();
      ''';

  static Future<void> setVolume(
    YoutubeJsChannel? channel,
    double volume,
  ) async {
    await channel?.evaluate(setVolumeScript(volume));
  }

  static Future<void> loadWatchPage(
    YoutubeJsChannel? channel,
    String videoId,
  ) async {
    await channel?.loadUri(watchUri(videoId));
  }

  static Future<void> loadIdlePage(YoutubeJsChannel? channel) async {
    await channel?.loadUri(idleUri);
  }

  /// Re-applies `playsinline` on the active `<video>` (iOS WKWebView safety net).
  static Future<void> forceInlinePlayback(YoutubeJsChannel? channel) async {
    await channel?.evaluate('''
        (function(){
          $_findVideoAndPlayer
          if(!v) return;
          v.setAttribute('playsinline','');
          v.setAttribute('webkit-playsinline','');
          v.playsInline=true;
          if(typeof v.webkitSetPresentationMode==='function'){
            try{v.webkitSetPresentationMode('inline');}catch(e){}
          }
        })();
      ''');
  }

  // ---
  // State poll (folded here from the deleted YoutubeStatePoller — issue #767;
  // its decode is now directly executable by tests).
  // ---

  /// Polls the HTML5 `<video>` element for position / duration / play state.
  ///
  /// Returns null while an ad is showing (`ad-showing` on the player
  /// container) or when no `<video>` exists — the ad hand-off and reload
  /// choreography must not sample ad playback.
  static const String pollScript =
      '''
      (function(){
        $locateVideo
        if(!v) return null;
        if(p && p.classList.contains('ad-showing')) return null;
        var s=v.paused?0:(v.ended?2:1);
        return JSON.stringify({
          t:v.currentTime||0,
          d:(v.duration && isFinite(v.duration))?v.duration:0,
          s:s
        });
      })();
    ''';

  /// Decodes a [pollScript] result.
  ///
  /// The `s` encoding is the protocol contract: `0` = paused, `1` = playing,
  /// `2` = ended. `t` / `d` are seconds. Returns null for null, non-JSON,
  /// non-object results (the WebView may be mid-teardown) — and for SHAPE
  /// drift: a missing or mistyped `t` / `s`, or an `s` outside 0/1/2 (issue
  /// #767 review). Defaulting those used to read as "playing at t=0", a
  /// false-positive the poll loop cannot distinguish from real DOM state;
  /// a null sample instead just drops the tick (the same swallow `poll`
  /// applies when the evaluate itself fails) and the next tick re-samples.
  /// `d` stays lenient — the page sends `0` for "no finite duration yet",
  /// so absence and zero are the same semantic and cannot fabricate
  /// transport state.
  static YoutubePollSample? decodePollSample(Object? result) {
    if (result == null) return null;
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(result.toString()) as Map<String, dynamic>;
    } on Object {
      return null;
    }

    final rawSeconds = json['t'];
    final rawState = json['s'];
    if (rawSeconds is! num || rawState is! num) return null;
    final state = rawState.toInt();
    const kStatePaused = 0;
    const kStatePlaying = 1;
    const kStateEnded = 2;
    if (state != kStatePaused &&
        state != kStatePlaying &&
        state != kStateEnded) {
      return null;
    }

    final position = Duration(
      milliseconds: (rawSeconds.toDouble() * 1000).round(),
    );
    final jsPaused = state == kStatePaused;
    final jsEnded = state == kStateEnded;

    Duration? newDuration;
    final dur = (json['d'] as num?)?.toDouble() ?? 0;
    if (dur > 0 && dur.isFinite) {
      newDuration = Duration(milliseconds: (dur * 1000).round());
    }

    return (
      position: position,
      duration: newDuration,
      paused: jsPaused,
      ended: jsEnded,
    );
  }

  /// One poll tick: evaluate [pollScript] and hand the decoded sample to
  /// [onResult]. No-ops when disposed or the channel is gone; swallows
  /// evaluation errors (the WebView may be disposed mid-teardown).
  static Future<void> poll({
    required bool disposed,
    required YoutubeJsChannel? channel,
    required void Function({
      required Duration position,
      Duration? newDuration,
      required bool jsPaused,
      required bool jsEnded,
    })
    onResult,
  }) async {
    if (disposed || channel == null) return;
    try {
      final sample = decodePollSample(await channel.evaluate(pollScript));
      if (sample == null) return;
      onResult(
        position: sample.position,
        newDuration: sample.duration,
        jsPaused: sample.paused,
        jsEnded: sample.ended,
      );
    } on Object {
      // WebView may be disposed — ignore.
    }
  }
}
