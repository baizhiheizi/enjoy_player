/// Scripted second adapter over the [YoutubeJsChannel] seam (issue #767).
///
/// Production evaluates through `InAppWebViewJsChannel`; tests evaluate
/// through this — recording every source the protocol module asks to run and
/// playing back queued results (or throwing, to exercise the swallow paths).
/// The protocol can now be *executed* in tests instead of regexed.
library;

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_js_channel.dart';

class ScriptedJsChannel implements YoutubeJsChannel {
  ScriptedJsChannel({List<Object?>? results, this.throwOnEvaluate = false})
    : _results = [...?results];

  /// Queued results, handed back one per [evaluate] in order; an empty queue
  /// evaluates to null (the WebView's undefined).
  final List<Object?> _results;

  /// When true, every channel call throws — the WebView-mid-teardown path.
  /// Applies to BOTH [evaluate] and [loadUri]: a dying WebView kills the
  /// whole channel, not just script evaluation.
  final bool throwOnEvaluate;

  /// Every source handed to [evaluate], in call order.
  final List<String> evaluatedSources = [];

  /// Every uri handed to [loadUri], in call order.
  final List<Uri> loadedUris = [];

  @override
  Future<Object?> evaluate(String source) async {
    evaluatedSources.add(source);
    if (throwOnEvaluate) throw StateError('boom');
    if (_results.isEmpty) return null;
    return _results.removeAt(0);
  }

  @override
  Future<void> loadUri(Uri uri) async {
    if (throwOnEvaluate) throw StateError('boom');
    loadedUris.add(uri);
  }
}
