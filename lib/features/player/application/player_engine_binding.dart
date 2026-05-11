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
Future<void> ensureEngineForPlayableSource(
  Ref ref, {
  required PlayableSource playable,
  required PlayerEngine? Function() getOwnedEngine,
  required void Function(PlayerEngine? next) setOwnedEngine,
}) async {
  if (ref.read(playerEngineTestDoubleProvider) != null) return;
  final wantYt = playable is YoutubePlayableSource;
  final owned = getOwnedEngine();
  final haveYt = owned is YoutubePlayerEngine;
  if (wantYt && !haveYt) {
    if (owned != null) {
      await owned.dispose();
    }
    setOwnedEngine(YoutubePlayerEngine());
    ref.read(playerEngineRevProvider.notifier).bump();
    return;
  }
  if (!wantYt && haveYt) {
    await owned.dispose();
    setOwnedEngine(MediaKitPlayerEngine());
    ref.read(playerEngineRevProvider.notifier).bump();
  }
}
