/// Status pill badge: 24px stadium with the emphasized ink fill or the
/// quiet sunk fill.
///
/// Shared by the credits usage log's allowed/denied badges and the
/// subscription status card's trailing chip, which were boolean mirrors of
/// one primitive (ADR-0018).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class EnjoyPillBadge extends StatelessWidget {
  const EnjoyPillBadge({
    super.key,
    required this.label,
    this.emphasized = false,
    this.fillWidth = false,
  });

  final String label;

  /// High-emphasis treatment: ink fill with a paper label. The default
  /// renders the quiet twin — sunk fill with an ink2 label.
  final bool emphasized;

  /// When `true` the pill stretches to the width its parent offers instead
  /// of fitting the pill to its label.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: emphasized ? t.paper : t.ink2,
      ),
    );
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: fillWidth ? Alignment.center : null,
      decoration: ShapeDecoration(
        color: emphasized ? t.ink : t.sunk,
        shape: const StadiumBorder(),
      ),
      child: fillWidth ? text : Center(widthFactor: 1, child: text),
    );
  }
}
