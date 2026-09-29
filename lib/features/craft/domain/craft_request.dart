/// Craft request value object and normalization helper.
library;

import 'package:enjoy_player/core/utils/text_normalization.dart';

/// Normalizes text for hashing and synthesis: NFC-normalize, collapse
/// whitespace runs to single spaces, trim leading/trailing.
String normalizeCraftText(String input) {
  final collapsed = collapseWhitespace(input);
  return collapsed;
}

/// The minimum text length (post-normalize) for the Craft action to be enabled.
const int craftMinTextLength = 10;

/// The maximum text length (post-normalize) before truncation notice applies.
const int craftMaxTextLength = 5000;
