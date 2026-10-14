/// The player's three lenses on one transcript (ADR-0093, canvas v30).
library;

enum PlayerLens { listen, echo, dictate }

/// Echo wins when a legacy session restored both flags.
PlayerLens playerLensFrom({required bool echoActive, required bool hideText}) =>
    echoActive
    ? PlayerLens.echo
    : hideText
    ? PlayerLens.dictate
    : PlayerLens.listen;
