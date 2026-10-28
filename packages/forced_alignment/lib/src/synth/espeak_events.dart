/// One eSpeak `espeak_EVENT_WORD` mark.
///
/// [textPosition] is 1-based and [length] counts source characters, but
/// eSpeak does not emit one event per orthographic token: function words can
/// be swallowed (no event), expansions can emit several events with shifted
/// positions (`77` → "seventy seven"), and some events report `length == 0`.
/// Display labels never come from these fields; only [textPosition] and
/// [audioMs] drive the mapping, and [length] is informational.
final class EspeakWordEvent {
  const EspeakWordEvent({
    required this.textPosition,
    required this.length,
    required this.audioMs,
  });

  final int textPosition;

  /// Informational: captured verbatim from eSpeak but never read by the
  /// token mapping.
  final int length;
  final int audioMs;
}

/// One eSpeak `espeak_EVENT_PHONEME` mark.
final class EspeakPhoneEvent {
  const EspeakPhoneEvent({
    required this.phone,
    required this.audioMs,
    required this.textPosition,
  });

  final String phone;
  final int audioMs;
  final int textPosition;
}
