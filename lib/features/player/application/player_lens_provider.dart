/// The active [PlayerLens], derived from echo mode and hide-text mode.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/domain/player_lens.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';

part 'player_lens_provider.g.dart';

@riverpod
PlayerLens playerLens(Ref ref) => playerLensFrom(
  echoActive: ref.watch(echoModeProvider).active,
  hideText: ref.watch(transcriptBlurModeProvider),
);
