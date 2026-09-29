import 'package:enjoy_player/features/player/application/engines/youtube/youtube_page_inject.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubeWebViewBridge play script', () {
    test('preserves audible state and reports rejected play promises', () {
      expect(
        YoutubeWebViewBridge.playScript,
        isNot(matches(RegExp('mute', caseSensitive: false))),
      );
      expect(
        YoutubeWebViewBridge.playScript,
        contains("'onVideoEvent','playRejected'"),
      );
      expect(YoutubeWebViewBridge.playScript, contains('.catch(rejected)'));
    });
  });

  group('kYoutubeMobileWatchInjectScript playback', () {
    test('does not force unmute before playback is confirmed', () {
      expect(kYoutubeMobileWatchInjectScript, isNot(contains('muted=false')));
      expect(kYoutubeMobileWatchInjectScript, isNot(contains('volume=1')));
    });
  });

  group('kYoutubeMobileWatchInjectScript captions', () {
    test('force-hides YouTube native caption/subtitle DOM via CSS', () {
      expect(
        kYoutubeMobileWatchInjectScript,
        contains('.ytp-caption-window-container'),
      );
      expect(
        kYoutubeMobileWatchInjectScript,
        contains('display:none!important;visibility:hidden!important;'),
      );
    });

    test('disables native <track>-based textTracks on hook and enforce', () {
      expect(
        kYoutubeMobileWatchInjectScript,
        contains('function disableTextTracks(video)'),
      );
      expect(
        kYoutubeMobileWatchInjectScript,
        contains("video.textTracks[i].mode='disabled';"),
      );

      final hookVideoBody = kYoutubeMobileWatchInjectScript.substring(
        kYoutubeMobileWatchInjectScript.indexOf('function hookVideo(video){'),
        kYoutubeMobileWatchInjectScript.indexOf('function syncState(video){'),
      );
      expect(hookVideoBody, contains('disableTextTracks(video);'));

      final enforceBody = kYoutubeMobileWatchInjectScript.substring(
        kYoutubeMobileWatchInjectScript.indexOf('function enforce(){'),
        kYoutubeMobileWatchInjectScript.indexOf('function setup(){'),
      );
      expect(enforceBody, contains('disableTextTracks(v);'));
    });

    test('unloads YouTube captions/cc modules via player API', () {
      expect(
        kYoutubeMobileWatchInjectScript,
        contains('function disableYoutubeCaptions()'),
      );
      expect(
        kYoutubeMobileWatchInjectScript,
        contains("p.unloadModule('captions')"),
      );
      expect(
        kYoutubeMobileWatchInjectScript,
        contains("p.setOption('captions','track',{})"),
      );

      final enforceBody = kYoutubeMobileWatchInjectScript.substring(
        kYoutubeMobileWatchInjectScript.indexOf('function enforce(){'),
        kYoutubeMobileWatchInjectScript.indexOf('function setup(){'),
      );
      expect(enforceBody, contains('hideCaptionDom();'));
      expect(enforceBody, contains('disableYoutubeCaptions();'));
    });
  });

  group('kYoutubeMobileWatchInjectScript enforcement cadence', () {
    final script = kYoutubeMobileWatchInjectScript;

    test('does not rewrite the layout on a 300 ms interval', () {
      expect(script, isNot(contains('setInterval(enforce,300)')));
      expect(RegExp(r'setInterval\(').allMatches(script), hasLength(1));
      expect(script, contains('setInterval(enforce,1000)'));
    });

    test('re-enforces reactively from a MutationObserver', () {
      expect(script, contains('new MutationObserver(scheduleEnforce)'));
      expect(script, contains('childList:true,subtree:true'));
      expect(script, contains("attributeFilter:['class','style']"));
      expect(script, contains('function observeLayoutTargets()'));
      final enforceBody = script.substring(
        script.indexOf('function enforce(){'),
        script.indexOf('function setup(){'),
      );
      expect(enforceBody, contains('observeLayoutTargets();'));
    });

    test('coalesces a mutation burst into a single sweep', () {
      expect(script, contains('function scheduleEnforce()'));
      expect(script, contains('if(enforcePending||reloading) return;'));
    });

    test('each element is written at most once (bounded invocations)', () {
      expect(script, contains('function styleOnce(el,props,mark)'));
      expect(script, contains('if(el[STAMP]){\n      if(!mark) return;'));
      expect(
        RegExp(r'getPropertyValue\(mark\)').allMatches(script),
        hasLength(1),
      );
      expect(RegExp(r'function styleOnce\(').allMatches(script), hasLength(1));
      final styleOnceBody = script.substring(
        script.indexOf('function styleOnce('),
        script.indexOf('  // Re-apply inline hide'),
      );
      expect(
        RegExp(r'\.style\.setProperty\(').allMatches(script),
        hasLength(1),
      );
      expect(styleOnceBody, contains('.style.setProperty('));
      expect(script, contains('function applyLayout()'));
      expect(script, contains('applyLayout();'));
    });

    test(
      'ad transitions are derived from the observer, not a poll cadence',
      () {
        expect(script, contains("player.classList.contains('ad-showing')"));
        expect(script, contains("callHandler('onAdReload',savedTime)"));
        expect(script, contains("video.addEventListener('timeupdate'"));
        final eventsArray = RegExp(
          r'var events=\[([^\]]*)\]',
        ).firstMatch(script)!.group(1)!;
        expect(eventsArray, isNot(contains('timeupdate')));
      },
    );

    test(
      'single-inject guard, focus pin and syncState hand-off are intact',
      () {
        expect(script, contains('if(window.__enjoyYtMwc){return;}'));
        expect(script, contains('document.hasFocus=function(){return true;}'));
        expect(script, contains('function syncState(video)'));
        expect(script, contains('setTimeout(function(){syncState(v);},200);'));
      },
    );
  });
}
