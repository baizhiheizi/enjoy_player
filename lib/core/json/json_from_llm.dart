/// JSON-object extraction for LLM responses.
///
/// LLMs prompted to "reply with JSON" frequently wrap their answer in a
/// ```json fenced code block, sometimes with a leading language tag, sometimes
/// not. The exact fence shape drifts between providers (and between
/// individual model runs), so callers historically reinvented the same
/// "strip fences, fall back to the outermost `{…}` braces" recipe.
///
/// [extractJsonObject] centralizes that recipe so any LLM-backed capability
/// can pull a JSON object out of a fenced / unfenced / partially-fenced
/// response without re-implementing fence-stripping.
library;

/// Returns the JSON-object substring of [raw].
///
/// Strategy:
/// 1. If the trimmed response starts with `{`, it is returned verbatim.
/// 2. Otherwise the first ``` fence (with its optional language tag) is
///    stripped and the content between the opening and closing fence is
///    returned.
/// 3. Otherwise the substring between the first `{` and the last `}` is
///    returned as a best-effort object slice.
///
/// Throws [FormatException] if the response contains no `{` and no fences.
String extractJsonObject(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('{')) return trimmed;

  final fenceStart = trimmed.indexOf('```');
  if (fenceStart >= 0) {
    final afterFence = trimmed.indexOf('\n', fenceStart);
    final endFence = trimmed.lastIndexOf('```');
    if (afterFence >= 0 && endFence > afterFence) {
      return trimmed.substring(afterFence + 1, endFence).trim();
    }
  }

  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return trimmed.substring(start, end + 1);
  }

  throw const FormatException('LLM response is not JSON');
}
