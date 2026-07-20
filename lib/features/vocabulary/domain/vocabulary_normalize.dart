/// Word normalization for vocabulary identity (parity with web
/// `lib/vocabulary-utils.ts` `normalizeWord`).
library;

/// Lowercase, trim, strip non letter/number/space (Unicode-aware).
String normalizeWord(String word) => word.toLowerCase().trim().replaceAll(
  RegExp(r'[^\p{L}\p{N}\s]', unicode: true),
  '',
);
