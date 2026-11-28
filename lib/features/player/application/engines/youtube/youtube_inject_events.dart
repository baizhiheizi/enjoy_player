/// Third slice of the watch-page injection payload: the <video> event
/// hooks and the page-to-Dart state hand-off.
library;

const String kYoutubeInjectEventsScript =
    r'''  // --- Attach event hooks to a <video> element ---
  function hookVideo(video){
    enableInlinePlayback(video);
    disableTextTracks(video);
    disableYoutubeCaptions();
    video.addEventListener('webkitbeginfullscreen',function(){
      if(typeof video.webkitSetPresentationMode==='function'){
        try{video.webkitSetPresentationMode('inline');}catch(e){}
      }
    },true);
    var events=['play','playing','pause','ended',
                'waiting','canplay','error','loadedmetadata'];
    events.forEach(function(e){
      video.addEventListener(e,function(){
        // Ad playback must not drive Dart transport (playing/pause/polling).
        if(isAd()) return;
        var args=[e];
        if(e==='loadedmetadata') args.push(video.duration||0);
        if(e==='pause') args.push(pauseContext(video));
        window.flutter_inappwebview.callHandler(
          'onVideoEvent',args[0],args.length>1?args[1]:null);
      });
    });
    // Position sampler for the ad hand-off (issue #662): [savedTime] used to
    // be refreshed by the same 300 ms tick that ran the layout pass, so with
    // that tick gone it needs a driver of its own. `timeupdate` (~4 Hz while
    // playing) is free — page-local, no Dart round-trip. Deliberately NOT in
    // [events]: it must never reach the Dart transport switch.
    video.addEventListener('timeupdate',function(){
      if(isAd()) return;
      if(isFinite(video.currentTime)&&video.currentTime>0){
        savedTime=video.currentTime;
      }
    });
  }

  // Page-side state at the moment of a pause — the Dart side cannot ask the
  // page WHY it paused (a DOM pause carries no initiator), so every pause
  // ships its context for diagnostic logs: page-corrected pauses (the
  // play-then-pause bug class) correlate with hidden/unfocused documents or
  // a specific page-player state.
  function pauseContext(video){
    var ps='?';
    try{
      var p=document.querySelector('#movie_player');
      if(p&&typeof p.getPlayerState==='function') ps=p.getPlayerState();
    }catch(e){}
    var vis='?';
    try{vis=document.visibilityState;}catch(e){}
    var foc='?';
    try{foc=document.hasFocus()?'1':'0';}catch(e){}
    var muted='?';
    try{muted=video.muted?'1':'0';}catch(e){}
    // Starvation evidence (field round 5): a page pause with pstate=3
    // (buffering), readyState < 3 and ~0 s buffered ahead is buffer
    // exhaustion, not a policy pause — the retries must wait for data.
    var rs='?';
    try{rs=video.readyState;}catch(e){}
    var buf='?';
    try{
      buf='0';
      for(var i=0;i<video.buffered.length;i++){
        if(video.buffered.start(i)<=video.currentTime&&
           video.currentTime<video.buffered.end(i)){
          buf=(video.buffered.end(i)-video.currentTime).toFixed(1);
          break;
        }
      }
    }catch(e){}
    var vol='?';
    try{vol=(video.volume==null?'?':video.volume);}catch(e){}
    return 'vis='+vis+' foc='+foc+' muted='+muted+' vol='+vol+
           ' pstate='+ps+' rs='+rs+' buf='+buf;
  }

  // --- Sync current video state to Dart ---
  function syncState(video){
    if(!video||isAd()) return;
    if(video.readyState>=1){
      window.flutter_inappwebview.callHandler(
        'onVideoEvent','loadedmetadata',video.duration||0);
    }
    if(!video.paused && !video.ended){
      window.flutter_inappwebview.callHandler('onVideoEvent','playing');
    }else if(video.ended){
      window.flutter_inappwebview.callHandler('onVideoEvent','ended');
    }else{
      window.flutter_inappwebview.callHandler(
        'onVideoEvent','pause',pauseContext(video));
    }
  }

''';
