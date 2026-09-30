/// Shared field outline for the Craft tool panels: hairline at rest, iris on
/// focus.
///
/// Promoted out of `synthesize_tool.dart` and `translate_tool.dart`, which
/// carried byte-identical private copies.
library;

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';

OutlineInputBorder craftFieldBorder(
  EnjoyThemeTokens t, {
  bool focused = false,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radiusMd),
    borderSide: BorderSide(
      color: focused ? t.accentInk : t.hairline,
      width: focused ? 1.5 : 1,
    ),
  );
}
