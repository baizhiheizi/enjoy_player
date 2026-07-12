/// Markdown explanation from worker `/chat/completions` (contextual translation).
final class ContextualTranslationResult {
  const ContextualTranslationResult({required this.translatedText});

  final String translatedText;

  factory ContextualTranslationResult.fromJson(Map<String, dynamic> json) =>
      ContextualTranslationResult(
        translatedText: json['translatedText'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'translatedText': translatedText,
  };
}
