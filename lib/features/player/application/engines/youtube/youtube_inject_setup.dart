/// Last slice of the watch-page injection payload: the session
/// bootstrap and the history guard that keeps the player on one
/// video.
library;

const String kYoutubeInjectSetupScript = r'''  function setup(){
    v=mainVideo();
    if(!v){setTimeout(setup,300);return;}

    player=v.closest('.html5-video-player')||v.parentElement;
    rebuildMids();

    chain=[];
    var tmp=player;
    while(tmp){chain.push(tmp);tmp=tmp.parentElement;}

    installInlineGuards();
    enforce();
    installLayoutObservers();

    // Belt-and-braces only — the observers carry enforcement (see
    // [installLayoutObservers]). One sweep a second costs a pass of expando
    // reads because of [STAMP], where the 300 ms full rewrite this replaced
    // invalidated layout for the whole session. It is also the only driver
    // on a WebView without MutationObserver, and the last resort for a style
    // overwrite on an element the attribute observer does not pin.
    setInterval(enforce,1000);

    v.autoplay=false;
    v.removeAttribute('autoplay');
    v.loop=false;

    hookVideo(v);

    var origPush=history.pushState.bind(history);
    var origReplace=history.replaceState.bind(history);
    history.pushState=function(s,t,u){
      if(u && typeof u==='string' && u.indexOf('/watch')>=0){
        try{
          var nv=(new URL(u,location.href)).searchParams.get('v');
          if(nv && nv!==curVid) return;
        }catch(e){}
      }
      origPush(s,t,u);
    };
    history.replaceState=function(s,t,u){
      if(u && typeof u==='string' && u.indexOf('/watch')>=0){
        try{
          var nv=(new URL(u,location.href)).searchParams.get('v');
          if(nv && nv!==curVid) return;
        }catch(e){}
      }
      origReplace(s,t,u);
    };

    syncState(v);
  }
  setup();
})();
''';
