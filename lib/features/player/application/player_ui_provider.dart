/// Player chrome: mini vs expanded (transport reads playing/buffering from [playerIsPlayingProvider]).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_ui_provider.g.dart';

enum PlayerChromeMode { mini, expanded }

class PlayerUiState {
  const PlayerUiState({required this.mode});

  final PlayerChromeMode mode;

  static const initial = PlayerUiState(
    mode: PlayerChromeMode.mini,
  );

  PlayerUiState copyWith({
    PlayerChromeMode? mode,
  }) {
    return PlayerUiState(
      mode: mode ?? this.mode,
    );
  }
}

@Riverpod(keepAlive: true)
class PlayerUi extends _$PlayerUi {
  @override
  PlayerUiState build() => PlayerUiState.initial;

  void expand() {
    state = state.copyWith(mode: PlayerChromeMode.expanded);
  }

  void collapse() {
    state = state.copyWith(mode: PlayerChromeMode.mini);
  }

  void reset() {
    state = PlayerUiState.initial;
  }
}
