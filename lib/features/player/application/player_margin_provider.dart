/// What the player's side margin shows when it is docked in the layout
/// (canvas v30, D6.12). Presentation state only; narrower windows use the
/// drawer route instead and never set this.
library;

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_margin_provider.g.dart';

/// One margin panel: [id] keeps a reopened panel's state, [builder] draws it
/// with a callback that closes the margin.
@immutable
class PlayerMarginEntry {
  const PlayerMarginEntry({
    required this.id,
    required this.label,
    required this.builder,
    this.echoOnly = false,
  });

  final Object id;

  /// Closes when the player leaves Echo (takes, a take's assessment).
  final bool echoOnly;
  final String label;
  final Widget Function(BuildContext context, VoidCallback close) builder;
}

@Riverpod(keepAlive: true)
class PlayerMargin extends _$PlayerMargin {
  @override
  PlayerMarginEntry? build() => null;

  void show(PlayerMarginEntry entry) => state = entry;

  void close() {
    if (state != null) state = null;
  }
}
