/// Craft request value object and normalization helper.
library;

import 'package:enjoy_player/core/utils/text_normalization.dart';

/// Normalizes text for hashing and synthesis: collapse whitespace runs to
/// single spaces, trim leading/trailing.
String normalizeCraftText(String input) {
  final collapsed = collapseWhitespace(input);
  return collapsed;
}

/// The minimum text length (post-normalize) for the Craft action to be enabled.
const int craftMinTextLength = 10;

/// The maximum text length (post-normalize) before truncation notice applies.
const int craftMaxTextLength = 5000;

/// Whether [normalizeCraftText] would leave at least [craftMinTextLength]
/// characters.
bool meetsCraftMinTextLength(String input) =>
    _reachesCollapsedLength(input, craftMinTextLength);

/// The exact length of [normalizeCraftText], without building the string.
int collapsedLength(String input) {
  final start = _firstKeptIndex(input);
  if (start < 0) return 0;
  final last = _lastKeptIndex(input, start);
  var count = 0;
  var inRun = false;
  for (var i = start; i <= last; i++) {
    final unit = input.codeUnitAt(i);
    if (_isRegExpWhitespace(unit)) {
      if (!inRun) {
        count++;
        inRun = true;
      }
    } else {
      count++;
      inRun = false;
    }
  }
  return count;
}

bool _reachesCollapsedLength(String input, int limit) {
  final start = _firstKeptIndex(input);
  if (start < 0 || input.length - start < limit) return false;
  var count = 0;
  var inRun = false;
  for (var i = start; i < input.length; i++) {
    final unit = input.codeUnitAt(i);
    if (_isRegExpWhitespace(unit)) {
      if (!inRun) {
        count++;
        inRun = true;
      }
    } else {
      count++;
      inRun = false;
      if (unit != 0x85 && count >= limit) return true;
    }
  }
  return false;
}

int _firstKeptIndex(String input) {
  for (var i = 0; i < input.length; i++) {
    if (!_isTrimWhitespace(input.codeUnitAt(i))) return i;
  }
  return -1;
}

int _lastKeptIndex(String input, int start) {
  for (var i = input.length - 1; i >= start; i--) {
    if (!_isTrimWhitespace(input.codeUnitAt(i))) return i;
  }
  return start - 1;
}

bool _isRegExpWhitespace(int unit) => switch (unit) {
  0x09 ||
  0x0A ||
  0x0B ||
  0x0C ||
  0x0D ||
  0x20 ||
  0xA0 ||
  0x1680 ||
  >= 0x2000 && <= 0x200A ||
  0x2028 ||
  0x2029 ||
  0x202F ||
  0x205F ||
  0x3000 ||
  0xFEFF => true,
  _ => false,
};

bool _isTrimWhitespace(int unit) => switch (unit) {
  0x09 ||
  0x0A ||
  0x0B ||
  0x0C ||
  0x0D ||
  0x20 ||
  0x85 ||
  0xA0 ||
  0x1680 ||
  >= 0x2000 && <= 0x200A ||
  0x2028 ||
  0x2029 ||
  0x202F ||
  0x205F ||
  0x3000 ||
  0xFEFF => true,
  _ => false,
};
