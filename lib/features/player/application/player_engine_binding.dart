/// Swaps [PlayerEngine] implementation for YouTube vs local/URL (ADR-0015).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';

/// Ensures [_ownedEngine] matches [playable] (YouTube vs MediaKit), bumping
/// [playerEngineRevProvider] when the implementation changes.
///
/// [openGeneration] must match [currentOpenGeneration] before and after each
/// async step so concurrent [openMedia] calls cannot dispose another call's
/// engine mid-flight.
Future<void> ensureEngineForPlayableSource(
  Ref ref, {
  required PlayableSource playable,
  required int openGeneration,
  required int Function() currentOpenGeneration,
  required PlayerEngine? Function() getOwnedEngine,
  required void Function(PlayerEngine? next) setOwnedEngine,
}) async {
  if (ref.read(playerEngineTestDoubleProvider) != null) return;
  if (currentOpenGeneration() != openGeneration) return;

  final wantYt = playable is YoutubePlayableSource;
  final owned = getOwnedEngine();
  final haveYt = owned is YoutubePlayerEngine;

  if (wantYt && !haveYt) {
    if (currentOpenGeneration() != openGeneration) return;
    if (owned != null) {
      await owned.dispose();
      if (currentOpenGeneration() != openGeneration) return;
    }
    setOwnedEngine(YoutubePlayerEngine());
    ref.read(playerEngineRevProvider.notifier).bump();
    return;
  }

  if (!wantYt && haveYt) {
    if (currentOpenGeneration() != openGeneration) return;
    await owned.dispose();
    if (currentOpenGeneration() != openGeneration) return;
    setOwnedEngine(MediaKitPlayerEngine());
    ref.read(playerEngineRevProvider.notifier).bump();
  }
}
