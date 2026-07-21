/// Formats IPA with a single leading/trailing slash pair.
String formatVocabularyIpa(String raw) {
  var s = raw.trim();
  while (s.startsWith('/')) {
    s = s.substring(1);
  }
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  s = s.trim();
  return s.isEmpty ? '' : '/$s/';
}
