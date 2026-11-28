/// Second slice of the watch-page injection payload: caption
/// suppression — injected CSS, native <track> disabling and the
/// player-API caption module unload.
library;

const String kYoutubeInjectCaptionsScript =
    r'''  function installInlineGuards(){
    if(window.__enjoyYtInlineGuards){return;}
    window.__enjoyYtInlineGuards=1;
    var style=document.createElement('style');
    style.id='__enjoyYtInlineStyle';
    style.textContent=[
      '.ytp-fullscreen-button,.ytp-size-button,.fullscreen-icon',
      '{display:none!important;pointer-events:none!important;}',
      'button[aria-label*="Fullscreen"],button[aria-label*="全屏"]',
      '{display:none!important;pointer-events:none!important;}',
      // Captions must never render — app transcripts are the only caption
      // source (see docs/features/youtube.md). YouTube toggles these on by
      // default for some videos (auto-captions / saved viewer prefs), and
      // since the native control bar is hidden there is no way to turn them
      // off from the page itself.
      '.ytp-caption-window-container,.caption-window,',
      '.ytp-caption-window-bottom,.ytp-caption-window-top,',
      '.ytp-caption-window-rollup,.ytp-caption-segment,',
      '.player-captions-container,.captions-text',
      '{display:none!important;visibility:hidden!important;',
      'pointer-events:none!important;opacity:0!important;}'
    ].join('');
    document.head.appendChild(style);
  }

  // --- Never let native <track>-based captions render either ---
  function disableTextTracks(video){
    if(!video||!video.textTracks) return;
    try{
      for(var i=0;i<video.textTracks.length;i++){
        video.textTracks[i].mode='disabled';
      }
    }catch(e){}
  }

  var captionSel='.ytp-caption-window-container,.caption-window,'+
    '.ytp-caption-window-bottom,.ytp-caption-window-top,'+
    '.ytp-caption-window-rollup,.ytp-caption-segment,'+
    '.player-captions-container,.captions-text';

  // --- Write-once styling (issue #662) ---
  // Every element this script styles is stamped, and a stamped element is
  // never re-written unless its block has actually been undone: the property
  // blocks below are constants, so re-writing an intact one only invalidates
  // layout. This is what makes a reactive sweep cheap — a settled DOM costs a
  // handful of expando + CSS reads instead of ~40 !important property writes.
  var STAMP='__enjoyYtStyled';

  // [mark] is one property of the block, read back on later sweeps. Our
  // declarations are !important, so a page write to the same property loses
  // the cascade; only a removal or a wholesale style-attribute rewrite can
  // undo us, and that is exactly what a cleared [mark] detects. One property
  // read per element per sweep replaces the old 300 ms unconditional rewrite.
  function styleOnce(el,props,mark){
    if(!el) return;
    if(el[STAMP]){
      if(!mark) return;
      try{
        if(el.style.getPropertyValue(mark)===props[mark]) return;
      }catch(e){return;}
    }
    el[STAMP]=1;
    for(var k in props){
      if(Object.prototype.hasOwnProperty.call(props,k)){
        el.style.setProperty(k,props[k],'important');
      }
    }
  }

  // Re-apply inline hide — YouTube sometimes sets competing inline styles
  // that outrank a one-shot <style> rule after track changes. Fresh caption
  // nodes are unstamped, so each new window is hidden on the sweep that
  // observes it. The <style> rule in [installInlineGuards] is the other
  // backstop.
  function hideCaptionDom(){
    var root=player||document;
    var nodes=root.querySelectorAll
      ? root.querySelectorAll(captionSel)
      : [];
    for(var i=0;i<nodes.length;i++){
      styleOnce(nodes[i],{
        display:'none',
        visibility:'hidden',
        opacity:'0',
        'pointer-events':'none'
      },'display');
    }
  }

  // Turn off YouTube's own captions module when the player API is available
  // (watch-page #movie_player / .html5-video-player). CSS alone can miss
  // transient overlays / language pickers that sit outside caption nodes.
  // Only hit the player API when caption DOM is present so we do not spam
  // unloadModule every enforce tick.
  function disableYoutubeCaptions(){
    if(isAd()) return;
    var p=player||document.querySelector('.html5-video-player');
    if(!p) return;
    var hasCaptionDom=!!(
      p.querySelector(captionSel)||
      document.querySelector('.ytp-caption-window-container,.caption-window')
    );
    if(!hasCaptionDom && typeof p.getOption!=='function') return;
    if(!hasCaptionDom){
      try{
        var track=p.getOption('captions','track');
        if(!track||!track.languageCode) return;
      }catch(e){return;}
    }
    try{
      if(typeof p.unloadModule==='function'){
        p.unloadModule('captions');
        p.unloadModule('cc');
      }
    }catch(e){}
    try{
      if(typeof p.setOption==='function'){
        p.setOption('captions','track',{});
        p.setOption('cc','track',{});
      }
    }catch(e){}
  }

''';
