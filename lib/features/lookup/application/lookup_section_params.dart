/// Parameter objects for lookup sheet Riverpod families (value equality).
library;

import 'package:flutter/foundation.dart';

@immutable
final class LookupTranslationParams {
  const LookupTranslationParams({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final String text;
  final String sourceLanguage;
  final String targetLanguage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupTranslationParams &&
          text == other.text &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage;

  @override
  int get hashCode => Object.hash(text, sourceLanguage, targetLanguage);
}

@immutable
final class LookupContextualParams {
  const LookupContextualParams({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.context,
  });

  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final String? context;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupContextualParams &&
          text == other.text &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage &&
          context == other.context;

  @override
  int get hashCode =>
      Object.hash(text, sourceLanguage, targetLanguage, context);
}

@immutable
final class LookupDictionaryParams {
  const LookupDictionaryParams({
    required this.word,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final String word;
  final String sourceLanguage;
  final String targetLanguage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupDictionaryParams &&
          word == other.word &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage;

  @override
  int get hashCode => Object.hash(word, sourceLanguage, targetLanguage);
}
