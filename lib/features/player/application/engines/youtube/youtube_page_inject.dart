/// Injected on each YouTube mobile watch [onLoadStop] to hide chrome and hook events.
///
/// The payload is split across the sibling `youtube_inject_*.dart` slices so
/// each concern stays greppable. Every slice is a contiguous run of the
/// original single-payload script, so the concatenation is byte-identical to
/// the script this file used to hold.
library;

import 'youtube_inject_bootstrap.dart';
import 'youtube_inject_captions.dart';
import 'youtube_inject_enforcement.dart';
import 'youtube_inject_events.dart';
import 'youtube_inject_setup.dart';
import 'youtube_js_channel.dart';

const String kYoutubeMobileWatchInjectScript =
    kYoutubeInjectBootstrapScript +
    kYoutubeInjectCaptionsScript +
    kYoutubeInjectEventsScript +
    kYoutubeInjectEnforcementScript +
    kYoutubeInjectSetupScript;

Future<void> injectYoutubeMobileWatchPage(YoutubeJsChannel channel) {
  return channel.evaluate(kYoutubeMobileWatchInjectScript);
}
