/// Small pieces shared by the takes row under the Echo loop and the takes
/// list: take numbering, the play / pause glyph, and whether a take can be
/// scored.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/data/db/app_database.dart';

/// Takes arrive newest first; Take 1 is the oldest.
int takeNumberOf(List<RecordingRow> takes, RecordingRow row) {
  final i = takes.indexWhere((e) => e.id == row.id);
  if (i < 0) return takes.length;
  return takes.length - i;
}

/// The row [selectedId] names, or the latest take when it names none.
RecordingRow? resolveSelectedTake(
  List<RecordingRow> takes,
  String? selectedId,
) {
  if (takes.isEmpty) return null;
  for (final row in takes) {
    if (row.id == selectedId) return row;
  }
  return takes.first;
}

bool takeIsPlayable(RecordingRow row) {
  final path = row.localPath;
  return path != null && path.isNotEmpty;
}

bool takeCanBeScored(WidgetRef ref, RecordingRow row) {
  final learningLanguage = ref
      .watch(appPreferencesCtrlProvider)
      .valueOrNull
      ?.effectiveLearningLanguage;
  return takeIsPlayable(row) &&
      isAzurePronunciationAssessmentSupportedForPractice(
        row.language,
        learningLanguage: learningLanguage,
      );
}

/// Play, or pause while [row]'s file is the one playing.
class TakePlayGlyph extends ConsumerWidget {
  const TakePlayGlyph({
    required this.row,
    required this.color,
    this.size = 12,
    super.key,
  });

  final RecordingRow row;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(recordingPreviewPlayerProvider);
    final path = row.localPath;
    return StreamBuilder<bool>(
      stream: preview.playing,
      initialData: false,
      builder: (context, snap) {
        final playingThis =
            (snap.data ?? false) &&
            path != null &&
            path.isNotEmpty &&
            preview.loadedPath == File(path).absolute.path;
        return Icon(
          playingThis ? EnjoyIcons.pause : EnjoyIcons.play,
          size: size,
          color: color,
        );
      },
    );
  }
}
