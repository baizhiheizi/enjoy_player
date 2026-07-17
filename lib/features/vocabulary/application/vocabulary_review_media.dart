/// Media clip / player hand-off helpers for vocabulary review (single Player).
library;

import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// Time window for a [MediaLocator] in seconds.
typedef MediaClipWindow = ({double startSec, double endSec});

MediaClipWindow mediaLocatorWindow(MediaLocator locator) {
  final startSec = locator.start / 1000.0;
  final endSec = (locator.start + locator.duration) / 1000.0;
  return (startSec: startSec, endSec: endSec);
}

bool vocabularyContextSupportsMediaActions(VocabularyContext context) {
  if (context.sourceType == VocabularySourceType.ebook) return false;
  final locator = context.locator;
  if (locator == null || locator.duration <= 0) return false;
  if (context.sourceId.isEmpty) return false;
  return context.sourceType == VocabularySourceType.video ||
      context.sourceType == VocabularySourceType.audio;
}

/// Result of confirming open-in-player or shadow hand-off.
final class VocabularyMediaHandoff {
  const VocabularyMediaHandoff({
    required this.mediaId,
    required this.startSec,
    required this.endSec,
    required this.activateEcho,
  });

  final String mediaId;
  final double startSec;
  final double endSec;
  final bool activateEcho;
}

/// Plays / opens media through the shared [PlayerController] (never a 2nd Player).
Future<void> playVocabularyClip({
  required PlayerController player,
  required EchoMode echo,
  required VocabularyContext context,
}) async {
  if (!vocabularyContextSupportsMediaActions(context)) {
    throw StateError('Context does not support clip playback');
  }
  final locator = context.locator!;
  final window = mediaLocatorWindow(locator);
  await player.openMedia(context.sourceId);
  echo.activate(
    startLineIndex: -1,
    endLineIndex: -1,
    startTimeSeconds: window.startSec,
    endTimeSeconds: window.endSec,
  );
  await player.seekToSeconds(window.startSec);
  await player.play();
}

/// Opens media + optional echo after review hand-off.
Future<void> applyVocabularyMediaHandoff({
  required PlayerController player,
  required EchoMode echo,
  required VocabularyMediaHandoff handoff,
}) async {
  await player.openMedia(handoff.mediaId);
  if (handoff.activateEcho) {
    echo.activate(
      startLineIndex: -1,
      endLineIndex: -1,
      startTimeSeconds: handoff.startSec,
      endTimeSeconds: handoff.endSec,
    );
  } else {
    echo.deactivate();
  }
  await player.seekToSeconds(handoff.startSec);
  await player.play();
}
