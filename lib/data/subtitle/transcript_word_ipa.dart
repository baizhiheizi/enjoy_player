/// Stored-phone pronunciation helpers (no Flutter, no invented IPA).
library;

import 'dart:convert';

import 'package:meta/meta.dart';

import 'package:enjoy_player/data/subtitle/ipa_mapping.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

/// Repairs phones that were stored after a Latin-1 mis-decode of UTF-8.
///
/// Correct Unicode IPA (including Latin-1 Supplement like `æ`) is left alone;
/// classic mojibake (`Ã¦`, `É¡`) re-decodes to real IPA.
@visibleForTesting
String repairUtf8Mojibake(String value) {
  final units = value.codeUnits;
  if (units.isEmpty || units.every((u) => u < 128)) return value;
  if (units.any((u) => u > 255)) return value;
  try {
    return utf8.decode(units);
  } on FormatException {
    return value;
  }
}

/// Ordered non-empty [TranscriptPhone.phone] labels for [word].
List<String> wordIpaPieces(TranscriptWord word) {
  final phones = word.phones;
  if (phones == null || phones.isEmpty) return const [];
  return [
    for (final phone in phones)
      if (phone.phone.trim().isNotEmpty) repairUtf8Mojibake(phone.phone.trim()),
  ];
}

/// Familiar-form spellings memoized per word instance.
///
/// Weak keys: an entry dies with the word it was derived from, so no
/// eviction policy is needed.
final Expando<String> _spellingMemo = Expando<String>('wordIpaSpelling');

/// Number of familiar forms derived rather than read from [_spellingMemo].
@visibleForTesting
int wordIpaDerivationCount = 0;

/// Familiar-form pronunciation for overlay, or null when none.
String? wordIpaSpelling(TranscriptWord word) {
  final memoized = _spellingMemo[word];
  if (memoized != null) return memoized.isEmpty ? null : memoized;
  final spelling = _deriveWordIpaSpelling(word);
  _spellingMemo[word] = spelling;
  wordIpaDerivationCount++;
  return spelling.isEmpty ? null : spelling;
}

String _deriveWordIpaSpelling(TranscriptWord word) {
  final pieces = wordIpaPieces(word);
  if (pieces.isEmpty) return '';
  return formatPhonesAsFamiliarIpa(pieces);
}
