/// JS snippets and URL helpers for [YouTubePlayerEngine].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Shared by player + login WebViews — Google/YouTube reject default WKWebView UAs.
const String kYoutubeMobileChromeUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/134.0.0.0 Mobile Safari/537.36';

/// WebView settings for YouTube player and sign-in (keep UA aligned).
class YoutubeWebViewSettings {
  YoutubeWebViewSettings._();

  static InAppWebViewSettings forPlayer() {
    return InAppWebViewSettings(
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
    );
  }

  static InAppWebViewSettings forLogin() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      thirdPartyCookiesEnabled: true,
      userAgent: kYoutubeMobileChromeUserAgent,
    );
  }
}

class YoutubeWebViewBridge {
  YoutubeWebViewBridge._();

  static WebUri get idleUri => WebUri('about:blank');

  static WebUri watchUri(String videoId) =>
      WebUri('https://m.youtube.com/watch?v=$videoId');

  static Future<void> play(InAppWebViewController? web) async {
    await web?.evaluateJavascript(
      source: '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v) v.play();
        })();
      ''',
    );
  }

  static Future<void> pause(InAppWebViewController? web) async {
    await web?.evaluateJavascript(
      source: '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v) v.pause();
        })();
      ''',
    );
  }

  static Future<void> pauseVideoElement(InAppWebViewController? web) async {
    await web?.evaluateJavascript(
      source: '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v) v.pause();
        })();
      ''',
    );
  }

  static Future<void> seekToSeconds(
    InAppWebViewController? web,
    double seconds,
  ) async {
    await web?.evaluateJavascript(
      source:
          '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v) v.currentTime=$seconds;
        })();
      ''',
    );
  }

  static Future<void> stop(InAppWebViewController? web) async {
    await web?.evaluateJavascript(
      source: '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v){v.pause();v.currentTime=0;}
        })();
      ''',
    );
  }

  static Future<void> setPlaybackRate(
    InAppWebViewController? web,
    double speed,
  ) async {
    await web?.evaluateJavascript(
      source:
          '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v) v.playbackRate=$speed;
        })();
      ''',
    );
  }

  static Future<void> setVolume(
    InAppWebViewController? web,
    double volume,
  ) async {
    await web?.evaluateJavascript(
      source:
          '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(v){v.volume=$volume;v.muted=($volume<=0.001);}
        })();
      ''',
    );
  }

  static Future<void> loadWatchPage(
    InAppWebViewController? web,
    String videoId,
  ) async {
    await web?.loadUrl(urlRequest: URLRequest(url: watchUri(videoId)));
  }

  static Future<void> loadIdlePage(InAppWebViewController? web) async {
    await web?.loadUrl(urlRequest: URLRequest(url: idleUri));
  }

  /// Re-applies `playsinline` on the active `<video>` (iOS WKWebView safety net).
  static Future<void> forceInlinePlayback(InAppWebViewController? web) async {
    await web?.evaluateJavascript(
      source: '''
        (function(){
          var p=document.querySelector('.html5-video-player');
          var v=p?p.querySelector('video'):null;
          if(!v) v=document.querySelector('video');
          if(!v) return;
          v.setAttribute('playsinline','');
          v.setAttribute('webkit-playsinline','');
          v.playsInline=true;
          if(typeof v.webkitSetPresentationMode==='function'){
            try{v.webkitSetPresentationMode('inline');}catch(e){}
          }
        })();
      ''',
    );
  }
}
