/// Worker `/dictionary/query` result (camelCase JSON).
final class DictionaryResult {
  const DictionaryResult({
    required this.word,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.lemma,
    this.ipa,
    required this.senses,
  });

  final String word;
  final String sourceLanguage;
  final String targetLanguage;
  final String? lemma;
  final String? ipa;
  final List<DictionarySense> senses;

  factory DictionaryResult.fromJson(Map<String, dynamic> json) {
    final sensesRaw = json['senses'] as List<dynamic>? ?? const [];
    return DictionaryResult(
      word: json['word'] as String? ?? '',
      sourceLanguage: json['sourceLanguage'] as String? ?? '',
      targetLanguage: json['targetLanguage'] as String? ?? '',
      lemma: json['lemma'] as String?,
      ipa: json['ipa'] as String?,
      senses:
          sensesRaw
              .map(
                (e) =>
                    DictionarySense.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
    );
  }
}

final class DictionarySense {
  const DictionarySense({
    required this.definition,
    this.translation,
    this.partOfSpeech,
    this.examples,
    this.notes,
  });

  final String definition;
  final String? translation;
  final String? partOfSpeech;
  final List<DictionaryExample>? examples;
  final String? notes;

  factory DictionarySense.fromJson(Map<String, dynamic> json) {
    final ex = json['examples'] as List<dynamic>?;
    return DictionarySense(
      definition: json['definition'] as String? ?? '',
      translation: json['translation'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      notes: json['notes'] as String?,
      examples:
          ex
              ?.map(
                (e) => DictionaryExample.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
    );
  }
}

final class DictionaryExample {
  const DictionaryExample({required this.source, this.target});

  final String source;
  final String? target;

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      source: json['source'] as String? ?? '',
      target: json['target'] as String?,
    );
  }
}
