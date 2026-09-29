/// Character indices (exclusive end offsets) marking sentence ends in [text].
///
/// Aligned with web `getSentenceBoundaries` intent: treat `.?!` and fullwidth
/// `。！？` as terminators when followed by whitespace or end of string.
List<int> getSentenceBoundaries(String text, String primaryLanguage) {
  final boundaries = <int>[];
  if (text.isEmpty) return boundaries;

  final isZh = primaryLanguage.toLowerCase().split('-').first == 'zh';

  final re = RegExp(
    isZh
        ? r'[\.\!\?\。！？；]+(?:["\u201d\u2019\)\]\}」』])*(\s+|$)'
        : r'[\.\!\?\。！？]+(?:["\u201d\u2019\)\]\}」』])*(\s+|$)',
    multiLine: true,
  );
  for (final m in re.allMatches(text)) {
    boundaries.add(m.end);
  }
  return boundaries;
}
