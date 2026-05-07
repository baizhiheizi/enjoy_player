/// All subtitle tracks stored for a media item (embedded + imported).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transcript_track.dart';
import 'transcript_repository_provider.dart';

final allTranscriptsForMediaProvider =
    StreamProvider.family<List<TranscriptTrack>, String>((ref, mediaId) {
  return ref.watch(transcriptRepositoryProvider).watchTracks(mediaId);
});
