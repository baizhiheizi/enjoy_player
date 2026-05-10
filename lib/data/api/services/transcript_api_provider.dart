/// Riverpod wiring for [TranscriptApi].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/services/transcript_api.dart';

part 'transcript_api_provider.g.dart';

@Riverpod(keepAlive: true)
TranscriptApi transcriptApi(Ref ref) {
  return TranscriptApi(ref.watch(apiClientProvider));
}
