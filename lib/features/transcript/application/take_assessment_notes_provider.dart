/// Revision-keyed providers for scored-take pronunciation notes.
library;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/take_assessment_notes.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';

/// Decodes the mispronounced-word set once per assessment payload; payloads
/// above [kTakeAssessmentDecodeIsolateGate] leave the UI isolate.
final takeAssessmentErrorWordsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, assessmentJson) {
      if (assessmentJson.trim().isEmpty) return const <String>{};
      if (assessmentJson.length > kTakeAssessmentDecodeIsolateGate) {
        return compute(takeAssessmentErrorWords, assessmentJson);
      }
      return takeAssessmentErrorWords(assessmentJson);
    });

typedef TakeAssessmentNotesKey = ({
  String mediaId,
  String recordingId,
  String assessmentJson,
});

/// Line/word indexes for one scored take, memoized until the assessment or
/// the active transcript/echo changes.
final takeAssessmentNotesProvider = Provider.autoDispose
    .family<TakeAssessmentNotes?, TakeAssessmentNotesKey>((ref, key) {
      final errors = ref
          .watch(takeAssessmentErrorWordsProvider(key.assessmentJson))
          .value;
      if (errors == null || errors.isEmpty) return null;
      final lines =
          ref.watch(transcriptLinesForMediaProvider(key.mediaId)).value ??
          const <TranscriptLine>[];
      final echo = ref.watch(echoModeProvider);
      return TakeAssessmentNotes.from(
        lines: lines,
        echo: echo,
        errorWords: errors,
      );
    });
