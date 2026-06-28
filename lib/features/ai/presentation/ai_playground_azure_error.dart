/// Re-export the [AzureSpeechException] type and a formatter so the AI
/// playground can handle the SDK's error type without importing the
/// `azure_speech` package at the top of the playground widget file.
///
/// The playground is gated to debug builds via the router. Keeping the
/// `azure_speech` import behind this small helper file is a (small)
/// defense-in-depth measure: if a future refactor accidentally promotes
/// the playground to a release build, the SDK is still linked in (the
/// Azure plugin registers the platform implementation), but the import
/// only shows up in this one place.
library;

import 'package:azure_speech/azure_speech.dart';

/// True when [e] is an [AzureSpeechException]. Use in a generic catch
/// block so callers do not need to import `azure_speech` themselves.
bool isAzureSpeechException(Object e) => e is AzureSpeechException;

/// Format the SDK's error code and message for a log line / UI label.
/// Returns `null` when [e] is not an [AzureSpeechException] so the
/// caller can fall back to a generic error formatter.
String? formatAzureSpeechError(Object e) {
  if (e is! AzureSpeechException) return null;
  return 'AzureSpeech ${e.code}: ${e.message}';
}
