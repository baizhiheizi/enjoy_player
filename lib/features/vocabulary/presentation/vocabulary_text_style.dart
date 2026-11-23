/// Shared text helpers for vocabulary flashcard presentation.
library;

import 'package:enjoy_player/core/cache/lru_store.dart';
import 'package:material_ui/material_ui.dart';

final L1Store<String, RegExp> _highlightPatternCache = L1Store<String, RegExp>(
  capacity: 64,
);

/// Case-insensitive highlight of [word] within [text].
List<InlineSpan> highlightVocabularyWord({
  required String text,
  required String word,
  required TextStyle base,
  required TextStyle highlight,
}) {
  final needle = word.trim();
  if (needle.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: base)];
  }
  var pattern = _highlightPatternCache.peek(needle);
  if (pattern == null) {
    pattern = RegExp(RegExp.escape(needle), caseSensitive: false);
    _highlightPatternCache.put(needle, pattern);
  }
  final spans = <InlineSpan>[];
  var start = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > start) {
      spans.add(
        TextSpan(text: text.substring(start, match.start), style: base),
      );
    }
    spans.add(
      TextSpan(text: text.substring(match.start, match.end), style: highlight),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: base));
  }
  return spans.isEmpty ? [TextSpan(text: text, style: base)] : spans;
}

final _atxHeading = RegExp(r'^(#{1,3})\s+(.+)$');

/// Drops a leading ATX heading that duplicates the section label (e.g. `## 翻译`).
String stripRedundantContextualHeading(String markdown) {
  final trimmed = markdown.trimLeft();
  if (trimmed.isEmpty) return markdown;
  final lines = trimmed.split('\n');
  final first = lines.first.trim();
  final match = _atxHeading.firstMatch(first);
  if (match == null) return markdown;
  final title = match.group(2)!.trim().toLowerCase();
  const redundant = {
    '翻译',
    'translation',
    '译文',
    '语境翻译',
    'contextual translation',
  };
  if (!redundant.contains(title)) return markdown;
  return lines.skip(1).join('\n').trimLeft();
}

/// One titled body section from contextual AI markdown.
final class ContextualMarkdownSection {
  const ContextualMarkdownSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// Parsed contextual markdown: optional preamble + titled sections.
final class ContextualMarkdownDocument {
  const ContextualMarkdownDocument({
    required this.preamble,
    required this.sections,
  });

  final String preamble;
  final List<ContextualMarkdownSection> sections;

  bool get isEmpty => preamble.trim().isEmpty && sections.isEmpty;
}

final L1Store<String, ContextualMarkdownDocument> _markdownParses = L1Store(
  capacity: 8,
);

@visibleForTesting
int contextualMarkdownParseCount = 0;

/// Splits prepared markdown into a preamble and titled sections.
ContextualMarkdownDocument parseContextualMarkdownDocument(String markdown) {
  final cached = _markdownParses.peek(markdown);
  if (cached != null) return cached;
  contextualMarkdownParseCount++;
  final doc = _parseMarkdownDocument(markdown);
  _markdownParses.put(markdown, doc);
  return doc;
}

ContextualMarkdownDocument _parseMarkdownDocument(String markdown) {
  final prepared = stripRedundantContextualHeading(markdown);
  if (prepared.trim().isEmpty) {
    return const ContextualMarkdownDocument(preamble: '', sections: []);
  }

  final lines = prepared.split('\n');
  final preamble = <String>[];
  final sections = <ContextualMarkdownSection>[];
  var i = 0;

  while (i < lines.length && !_atxHeading.hasMatch(lines[i].trim())) {
    preamble.add(lines[i]);
    i++;
  }

  while (i < lines.length) {
    final match = _atxHeading.firstMatch(lines[i].trim());
    i++;
    final body = <String>[];
    while (i < lines.length && !_atxHeading.hasMatch(lines[i].trim())) {
      body.add(lines[i]);
      i++;
    }
    final bodyText = body.join('\n').trim();
    if (match == null || bodyText.isEmpty) continue;
    sections.add(
      ContextualMarkdownSection(title: match.group(2)!.trim(), body: bodyText),
    );
  }

  return ContextualMarkdownDocument(
    preamble: preamble.join('\n').trim(),
    sections: sections,
  );
}
