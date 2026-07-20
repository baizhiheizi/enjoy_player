/// Anki Basic CSV builder (web `export-csv.ts` parity).
library;

import 'dart:convert';

import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// Optional resolved source title for Back "Source:" line.
final class AnkiSourceReference {
  const AnkiSourceReference({required this.type, required this.title});

  final String type;
  final String title;
}

/// Builds Anki CSV text (without BOM). Columns: Front, Back, Tags.
String exportVocabularyToAnkiCsv({
  required List<VocabularyItem> items,
  required Map<String, List<VocabularyContext>> contextsByItemId,
  Map<String, AnkiSourceReference> sourceRefs = const {},
}) {
  final rows = <String>[
    '#separator:Comma',
    '#html:true',
    '#notetype:Basic',
    '#columns:Front,Back,Tags',
  ];

  for (final item in items) {
    final contexts = contextsByItemId[item.id] ?? const <VocabularyContext>[];
    final dictionary = decodeDictionaryExplanation(item.explanation);
    final front = _formatFront(item.word, contexts);
    final back = _formatBack(
      contexts: contexts,
      pronunciation: dictionary?.ipa ?? '',
      definition: _formatDefinition(dictionary),
      translation: _formatTranslation(dictionary),
      partOfSpeech: _formatPartOfSpeech(dictionary),
      examples: _formatExamples(dictionary),
      sourceReference: _formatSourceReferences(contexts, sourceRefs),
    );
    rows.add(_arrayToCsvRow([front, back, _formatTags(item)]));
  }

  return rows.join('\n');
}

/// UTF-8 bytes with leading BOM for Excel / Anki import.
List<int> ankiCsvWithBomBytes(String csv) => [
  0xEF,
  0xBB,
  0xBF,
  ...utf8.encode(csv),
];

String _escapeCsvField(String field) {
  if (field.isEmpty) return '';
  final needsQuoting =
      field.contains(',') ||
      field.contains('\n') ||
      field.contains('"') ||
      field.contains('\r');
  if (!needsQuoting) return field;
  return '"${field.replaceAll('"', '""')}"';
}

String _arrayToCsvRow(List<String> fields) =>
    fields.map(_escapeCsvField).join(',');

String _formatTags(VocabularyItem item) {
  final tags = <String>[
    'vocabulary',
    '${item.language}-${item.targetLanguage}',
  ];
  if (item.status != VocabularyStatus.new_) {
    tags.add(item.status.wire);
  }
  return tags.join(' ');
}

String _formatFront(String word, List<VocabularyContext> contexts) {
  final parts = <String>[
    '<div style="font-size: 2em; font-weight: bold; text-align: center; margin: 20px 0;">$word</div>',
  ];
  final contextText = contexts.map((c) => c.text).join('<hr>');
  if (contextText.isNotEmpty) {
    parts.add(
      '<div style="margin-top: 20px; padding: 10px; text-align: left; border-left: 4px solid #0066cc; border-radius: 3px;">'
      '<strong>Context:</strong><br>'
      '<span style="font-style: italic;">$contextText</span>'
      '</div>',
    );
  }
  return parts.join();
}

String _formatBack({
  required List<VocabularyContext> contexts,
  required String pronunciation,
  required String definition,
  required String translation,
  required String partOfSpeech,
  required String examples,
  required String sourceReference,
}) {
  final parts = <String>[];
  final contextTranslation = _formatContextTranslations(contexts);
  if (contextTranslation.isNotEmpty) {
    parts.add(
      '<div style="margin-bottom: 20px; padding: 10px; text-align: left; border-left: 4px solid #0066cc; border-radius: 3px;">'
      '<strong>Context Translation:</strong><br>'
      '<div>$contextTranslation</div>'
      '</div>',
    );
  }
  if (pronunciation.isNotEmpty) {
    parts.add(
      '<div style="text-align: center; color: #666; font-style: italic; margin-bottom: 10px;">[$pronunciation]</div>',
    );
  }
  if (translation.isNotEmpty) {
    parts.add(
      '<div style="text-align: center; font-size: 1.5em; font-weight: bold; margin: 15px 0; color: #0066cc;">$translation</div>',
    );
  }
  if (partOfSpeech.isNotEmpty) {
    parts.add(
      '<div style="text-align: left; font-style: italic; color: #888; margin-bottom: 10px;">$partOfSpeech</div>',
    );
  }
  if (definition.isNotEmpty) {
    parts.add(
      '<div style="text-align: left; margin: 15px 0; line-height: 1.6;">'
      '<strong>Definition:</strong><br>$definition</div>',
    );
  }
  if (examples.isNotEmpty) {
    parts.add(
      '<div style="text-align: left; margin: 15px 0; padding: 10px; border-radius: 5px;">'
      '<strong>Examples:</strong><br>$examples</div>',
    );
  }
  if (sourceReference.isNotEmpty) {
    parts.add(
      '<div style="text-align: left; margin-top: 15px; font-size: 0.9em; color: #999;">Source: $sourceReference</div>',
    );
  }
  return parts.join();
}

String _formatContextTranslations(List<VocabularyContext> contexts) {
  final translations = <String>[];
  for (final ctx in contexts) {
    final decoded = decodeContextualExplanation(ctx.explanation);
    final text = decoded?.translatedText.trim() ?? '';
    if (text.isEmpty) continue;
    translations.add(markdownToHtmlSimple(text));
  }
  return translations.join('<hr>');
}

String _formatDefinition(DictionaryResult? dictionary) {
  final senses = dictionary?.senses;
  if (senses == null || senses.isEmpty) return '';
  return senses
      .asMap()
      .entries
      .map((e) => '${e.key + 1}. ${e.value.definition}')
      .join('<br>');
}

String _formatTranslation(DictionaryResult? dictionary) {
  final senses = dictionary?.senses;
  if (senses == null || senses.isEmpty) return '';
  final unique = <String>{};
  for (final s in senses) {
    final t = s.translation?.trim();
    if (t != null && t.isNotEmpty) unique.add(t);
  }
  return unique.join('; ');
}

String _formatPartOfSpeech(DictionaryResult? dictionary) {
  final senses = dictionary?.senses;
  if (senses == null || senses.isEmpty) return '';
  final unique = <String>{};
  for (final s in senses) {
    final p = s.partOfSpeech?.trim();
    if (p != null && p.isNotEmpty) unique.add(p);
  }
  return unique.join(', ');
}

String _formatExamples(DictionaryResult? dictionary) {
  final senses = dictionary?.senses;
  if (senses == null || senses.isEmpty) return '';
  final parts = <String>[];
  for (final sense in senses) {
    final examples = sense.examples;
    if (examples == null) continue;
    for (final example in examples) {
      final source = example.source.trim();
      if (source.isEmpty) continue;
      final target = example.target?.trim();
      parts.add(
        target != null && target.isNotEmpty ? '$source<br>$target' : source,
      );
    }
  }
  return parts.join('<br><br>');
}

String _formatSourceReferences(
  List<VocabularyContext> contexts,
  Map<String, AnkiSourceReference> sourceRefs,
) {
  final refs = <String>[];
  for (final ctx in contexts) {
    final key = '${ctx.sourceType.wire}:${ctx.sourceId}';
    final ref = sourceRefs[key];
    if (ref != null) {
      refs.add('${ref.type}: ${ref.title}');
    }
  }
  return refs.join('; ');
}

/// Simple markdown → HTML (web `markdownToHtmlSimple` fallback).
String markdownToHtmlSimple(String markdown) {
  if (markdown.trim().isEmpty) return '';
  var html = markdown;
  html = html.replaceAllMapped(
    RegExp(r'^### (.*)$', multiLine: true),
    (m) => '<h3>${m[1]}</h3>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^## (.*)$', multiLine: true),
    (m) => '<h2>${m[1]}</h2>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^# (.*)$', multiLine: true),
    (m) => '<h1>${m[1]}</h1>',
  );
  html = html.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (m) => '<strong>${m[1]}</strong>',
  );
  html = html.replaceAllMapped(
    RegExp(r'\*([^*\n]+?)\*'),
    (m) => '<em>${m[1]}</em>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^[\-\*] (.+)$', multiLine: true),
    (m) => '<li>${m[1]}</li>',
  );
  html = html.replaceAllMapped(RegExp(r'(?:<li>.*?</li>\n?)+', dotAll: true), (
    m,
  ) {
    if (!m[0]!.contains('<ul>')) return '<ul>${m[0]}</ul>';
    return m[0]!;
  });
  html = html.replaceAll('  \n', '<br>');
  html = html.replaceAll('\n\n', '<br><br>');
  html = html.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => '<code>${m[1]}</code>',
  );
  html = html.replaceAllMapped(
    RegExp(r'```([\s\S]*?)```'),
    (m) => '<pre><code>${m[1]}</code></pre>',
  );
  html = html.replaceAll('\n', '<br>');
  return html;
}
