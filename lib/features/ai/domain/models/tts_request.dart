/// Placeholder until Azure / server-side TTS is wired.
final class TtsRequest {
  const TtsRequest({
    required this.text,
    required this.language,
    this.voice,
  });

  final String text;
  final String language;
  final String? voice;
}
