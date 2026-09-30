/// All subtitle tracks stored for a media item (embedded + imported).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transcript_track.dart';
import 'transcript_repository_provider.dart';

/// Subtitle tracks for one media item, disposed when the last watcher leaves.
///
/// `autoDispose` keeps the underlying Drift tracks watch from outliving the
/// player screen — the same C2 shape already applied to the per-media line
/// families, so opening an episode no longer pins every transcript you have
/// visited this session.
///
/// Consumers must therefore tolerate a warm-cache miss: [TransportCcButton]
/// renders no badge until tracks arrive, and the lookup sheet's
/// `ref.read(...).valueOrNull` already falls back to the learning language
/// whenever the sibling autoDispose `activeTranscriptIdProvider` is not warm.
final allTranscriptsForMediaProvider = StreamProvider.autoDispose
    .family<List<TranscriptTrack>, String>((ref, mediaId) {
      return ref.watch(transcriptRepositoryProvider).watchTracks(mediaId);
    });
