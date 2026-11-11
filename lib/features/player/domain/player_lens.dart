/// The player's three lenses on one transcript (ADR-0093, canvas v30).
library;

enum PlayerLens {
  listen,
  echo,
  dictate;

  bool get loopMode => this == echo || this == dictate;
  bool get dictationMode => this == dictate;
  bool get blurMode => this == dictate;
}

/// Invariant: echoActive + hideText -> dictate; echoActive alone -> echo; hideText alone -> dictate; none -> listen.
PlayerLens resolvePlayerLens({
  required bool echoActive,
  required bool hideText,
}) {
  if (hideText) return PlayerLens.dictate;
  if (echoActive) return PlayerLens.echo;
  return PlayerLens.listen;
}

PlayerLens playerLensFrom({required bool echoActive, required bool hideText}) =>
    resolvePlayerLens(echoActive: echoActive, hideText: hideText);
