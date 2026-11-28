/// Fourth slice of the watch-page injection payload: reactive layout
/// enforcement — DOM observers, the coalesced sweep and the ad
/// hand-off.
library;

const String kYoutubeInjectEnforcementScript =
    r'''  // --- Rebuild mids array for current video ---
  function rebuildMids(){
    mids=[];
    if(!v||!player) return;
    var tmp=v.parentElement;
    while(tmp && tmp!==player){mids.push(tmp);tmp=tmp.parentElement;}
  }

  // --- Reactive layout enforcement (issue #662) ---
  // The heavy pass below used to run on a 300 ms interval for as long as the
  // document lived: ~40 !important property writes across document / body /
  // player / mids / video, a querySelectorAll sweep and the ancestor sibling
  // scan — against a DOM that is settled a second after load. That is
  // continuous style + layout invalidation inside the WebView for a whole
  // session, for zero information. The pass now runs once per DOM shape and
  // is re-run reactively (see [installLayoutObservers]); [STAMP] is the
  // idempotence early-exit that keeps each reactive sweep cheap.

  // Structural churn anywhere in the document: YouTube injecting overlays,
  // caption windows or a rebuilt player, and any new sibling that the
  // ancestor scan must hide.
  // Attribute churn is watched on the pinned elements ONLY (subtree:false):
  // the progress bar and spinner inside the player rewrite style every
  // frame and must never schedule a sweep. `ad-showing` is a class on the
  // player container, so an ad transition rides this same record — the
  // ad-detection cadence is the observer, not a timer.
  var mo=null;

  function observeLayoutTargets(){
    if(!mo) return;
    mo.disconnect();
    try{
      mo.observe(document.documentElement,
                 {childList:true,subtree:true,attributes:false});
    }catch(e){}
    var pinned=[];
    if(player) pinned.push(player);
    if(v) pinned.push(v);
    for(var i=0;i<mids.length;i++){pinned.push(mids[i]);}
    for(i=0;i<pinned.length;i++){
      try{
        mo.observe(pinned[i],{
          childList:false,
          subtree:false,
          attributes:true,
          attributeFilter:['class','style']
        });
      }catch(e){}
    }
  }

  function installLayoutObservers(){
    if(typeof MutationObserver!=='function') return;
    try{mo=new MutationObserver(scheduleEnforce);}catch(e){mo=null;return;}
    observeLayoutTargets();
  }

  // Coalesce a mutation burst into one sweep. A plain short timer, not
  // requestAnimationFrame: rAF stops firing for a hidden/backgrounded view,
  // and this page is exactly the surface that gets parked (ADR-0066) — the
  // ad transition it would delay is the one we least want to miss.
  function scheduleEnforce(){
    if(enforcePending||reloading) return;
    enforcePending=true;
    setTimeout(function(){
      enforcePending=false;
      enforce();
    },50);
  }

  function applyLayout(){
    styleOnce(document.documentElement,
              {overflow:'hidden',background:'#000'},'overflow');
    styleOnce(document.body,
              {margin:'0',padding:'0',overflow:'hidden',background:'#000'},
              'margin');

    if(player){
      styleOnce(player,{
        position:'fixed',
        top:'0',
        left:'0',
        width:'100vw',
        height:'100vh',
        'z-index':'999999',
        overflow:'hidden',
        background:'#000',
        margin:'0',
        padding:'0',
        transform:'none',
        display:'block',
        visibility:'visible',
        opacity:'1'
      },'position');
    }

    mids.forEach(function(el){
      styleOnce(el,{
        width:'100%',
        height:'100%',
        display:'block',
        visibility:'visible',
        opacity:'1',
        position:'absolute',
        top:'0',
        left:'0',
        overflow:'hidden',
        'max-height':'none',
        'max-width':'none',
        'min-height':'0',
        margin:'0',
        padding:'0',
        transform:'none',
        background:'#000'
      },'min-height');
    });

    if(v){
      styleOnce(v,{
        width:'100%',
        height:'100%',
        position:'absolute',
        top:'0',
        left:'0',
        display:'block',
        visibility:'visible',
        'object-fit':'contain',
        margin:'0',
        padding:'0',
        transform:'none',
        background:'#000'
      },'object-fit');
    }

    for(var i=0;i<chain.length;i++){
      var parent=chain[i].parentElement;
      if(!parent) continue;
      Array.from(parent.children).forEach(function(sib){
        if(sib===chain[i]) return;
        var tag=sib.tagName;
        if(tag==='STYLE'||tag==='SCRIPT'||tag==='LINK'
           ||tag==='META'||tag==='HEAD') return;
        styleOnce(sib,{display:'none'},'display');
      });
    }
  }

  // --- Enforce layout + detect video swap + ad transition ---
  function enforce(){
    if(reloading) return;

    var adNow=isAd();
    if(!adNow && v && isFinite(v.currentTime) && v.currentTime>0){
      savedTime=v.currentTime;
    }

    if(!wasAd && adNow){
      wasAd=true;
    } else if(wasAd && !adNow){
      wasAd=false;
      reloading=true;
      window.flutter_inappwebview.callHandler('onAdReload',savedTime);
      window.flutter_inappwebview.callHandler('onVideoEvent','waiting');
      var url='https://m.youtube.com/watch?v='+curVid+(Math.floor(savedTime)>0?'&t='+Math.floor(savedTime)+'s':'');
      location.href=url;
      return;
    }

    var currentV=mainVideo();
    if(currentV && currentV!==v){
      v=currentV;
      hookVideo(v);
      rebuildMids();
      enableInlinePlayback(v);
      v.autoplay=false;
      v.removeAttribute('autoplay');
      v.loop=false;
      // The swapped <video> and its wrappers are new elements: re-point the
      // attribute observer at them before the next sweep.
      observeLayoutTargets();
      setTimeout(function(){syncState(v);},200);
    }
    if(!v) return;

    enableInlinePlayback(v);
    disableTextTracks(v);
    hideCaptionDom();
    disableYoutubeCaptions();

    applyLayout();
  }

''';
