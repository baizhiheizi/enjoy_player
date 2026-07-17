/// Shared text helpers for vocabulary flashcard presentation.
library;

import 'package:flutter/material.dart';

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
  final pattern = RegExp(RegExp.escape(needle), caseSensitive: false);
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

/// Removes ATX heading sections whose body is empty/whitespace-only.
String pruneEmptyMarkdownSections(String markdown) {
  final trimmed = markdown.trim();
  if (trimmed.isEmpty) return markdown;

  final lines = trimmed.split('\n');
  final out = <String>[];
  var i = 0;

  // Keep preamble until first heading.
  while (i < lines.length && !_atxHeading.hasMatch(lines[i].trim())) {
    out.add(lines[i]);
    i++;
  }

  while (i < lines.length) {
    final headingLine = lines[i];
    i++;
    final body = <String>[];
    while (i < lines.length && !_atxHeading.hasMatch(lines[i].trim())) {
      body.add(lines[i]);
      i++;
    }
    if (body.join('\n').trim().isEmpty) {
      continue;
    }
    out.add(headingLine);
    out.addAll(body);
  }

  return out.join('\n').trim();
}

/// Contextual markdown ready for flashcard display.
String prepareContextualMarkdown(String markdown) {
  return pruneEmptyMarkdownSections(stripRedundantContextualHeading(markdown));
}
