/// Markdown explanation from worker `/chat/completions` (contextual translation).
final class ContextualTranslationResult {
  factory ContextualTranslationResult.fromJson(Map<String, dynamic> json) =>
      ContextualTranslationResult(
        translatedText: json['translatedText'] as String,
      );

  const ContextualTranslationResult({required this.translatedText});

  final String translatedText;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'translatedText': translatedText,
  };
}
