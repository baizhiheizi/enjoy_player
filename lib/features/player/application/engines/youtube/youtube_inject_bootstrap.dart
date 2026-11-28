/// First slice of the watch-page injection payload: the single-inject
/// guard, the focus pin, video and player discovery, and the shared
/// page state the later slices read.
library;

const String kYoutubeInjectBootstrapScript = r'''(function(){
  // [onLoadStop] can run more than once (OAuth return, soft reloads). A second
  // inject stacks intervals + duplicate media listeners → spurious pause/sync.
  if(window.__enjoyYtMwc){return;}
  window.__enjoyYtMwc=1;

  // --- Focus pin ---
  // The embedding app parks this WebView off-corner for overlays (ADR-0066)
  // by translation only (size is preserved — a 320×180 shrink was itself
  // a pause stimulus). Android can still clear the view's focus in ways
  // the app cannot restore (the webview plugin exposes clearFocus but no
  // requestFocus). When the document reports itself unfocused, m.youtube.com's
  // player "corrects" programmatic playback back to paused within ~300-700 ms.
  // This page is an embedded, chrome-less player; nothing here legitimately
  // needs a focus signal, so pin it focused and dispatch a synthetic focus
  // event for page code that cached an unfocused flag from an earlier blur.
  // Dart re-asserts this on a real stage-size change and before each
  // automatic play retry (see YoutubeWebViewBridge.focusWindowScript).
  try{document.hasFocus=function(){return true;};}catch(e){}
  try{window.dispatchEvent(new Event('focus'));}catch(e){}

  function mainVideo(){
    var p=document.querySelector('.html5-video-player');
    if(!p) return document.querySelector('video');
    return p.querySelector('video')||document.querySelector('video');
  }

  var v=null;       // current hooked <video>
  var player=null;  // .html5-video-player container
  var mids=[];      // elements between player and <video>
  var chain=[];     // ancestors from player up to <html>
  var curVid=(new URL(location.href)).searchParams.get('v')||'';

  // --- Ad tracking ---
  var wasAd=false;        // was ad showing last cycle?
  var savedTime=0;        // last known main-video position
  var reloading=false;    // are we in the middle of a reload?

  // --- Reactive enforcement ---
  var enforcePending=false;  // a coalesced sweep is already queued

  // --- Utility ---
  function isAd(){
    return player && player.classList.contains('ad-showing');
  }

  function enableInlinePlayback(video){
    video.setAttribute('playsinline','');
    video.setAttribute('webkit-playsinline','');
    video.playsInline=true;
    if(typeof video.webkitSetPresentationMode==='function'){
      try{video.webkitSetPresentationMode('inline');}catch(e){}
    }
  }

''';
