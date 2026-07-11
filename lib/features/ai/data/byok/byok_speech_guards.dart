import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';

/// Persisted `SpeechByokConfig.kind` does not match the capability's expected
/// sub-protocol (e.g. an Azure Speech capability was given an OpenAI-compatible
/// configuration). Raised **before** any network or SDK call so the caller can
/// surface a misconfiguration without leaking a generic [StateError].
final class ByokMisconfiguredFailure implements Exception {
  const ByokMisconfiguredFailure({
    required this.expected,
    required this.actual,
    required this.capabilityLabel,
  });

  final SpeechByokKind expected;
  final SpeechByokKind actual;
  final String capabilityLabel;

  @override
  String toString() =>
      'ByokMisconfiguredFailure($capabilityLabel: expected ${expected.name}, '
      'got ${actual.name})';
}

typedef AzureSpeechCredentials = ({String region, String apiKey});
typedef OpenAiSpeechCredentials = ({
  String baseUrl,
  String model,
  String apiKey,
});

/// Validates an Azure-Speech [SpeechByokConfig] and returns the trimmed
/// `region` + BYOK API key for [ModalityKind.kind].
///
/// Throws:
/// - [ByokMisconfiguredFailure] if `config.kind != azureSpeech`.
/// - [ApiException] (400) if the region is missing.
/// - [ByokNotConfiguredFailure] if the BYOK API key is missing or blank.
Future<AzureSpeechCredentials> guardAzureSpeechConfig({
  required SpeechByokConfig config,
  required ByokSecretStoreBase secrets,
  required ModalityKind kind,
  required String capabilityLabel,
}) async {
  if (config.kind != SpeechByokKind.azureSpeech) {
    throw ByokMisconfiguredFailure(
      expected: SpeechByokKind.azureSpeech,
      actual: config.kind,
      capabilityLabel: capabilityLabel,
    );
  }

  final region = config.region?.trim();
  if (region == null || region.isEmpty) {
    throw ApiException(
      message: 'Azure region is not configured for $capabilityLabel BYOK',
      statusCode: 400,
    );
  }

  final apiKey = await secrets.readApiKey(kind);
  if (apiKey == null || apiKey.trim().isEmpty) {
    throw ByokNotConfiguredFailure(kind);
  }

  return (region: region, apiKey: apiKey.trim());
}

/// Validates an OpenAI-compatible [SpeechByokConfig] and returns the trimmed
/// `baseUrl` + `model` + BYOK API key for [ModalityKind.kind].
///
/// Throws:
/// - [ByokMisconfiguredFailure] if `config.kind != openAiCompatible`.
/// - [ApiException] (400) if `baseUrl` or `model` is missing.
/// - [ByokNotConfiguredFailure] if the BYOK API key is missing or blank.
Future<OpenAiSpeechCredentials> guardOpenAiSpeechConfig({
  required SpeechByokConfig config,
  required ByokSecretStoreBase secrets,
  required ModalityKind kind,
  required String capabilityLabel,
}) async {
  if (config.kind != SpeechByokKind.openAiCompatible) {
    throw ByokMisconfiguredFailure(
      expected: SpeechByokKind.openAiCompatible,
      actual: config.kind,
      capabilityLabel: capabilityLabel,
    );
  }

  final baseUrl = config.baseUrl?.trim();
  final model = config.model?.trim();
  if (baseUrl == null || baseUrl.isEmpty || model == null || model.isEmpty) {
    throw ApiException(
      message: '$capabilityLabel BYOK base URL and model are not configured',
      statusCode: 400,
    );
  }

  final apiKey = await secrets.readApiKey(kind);
  if (apiKey == null || apiKey.trim().isEmpty) {
    throw ByokNotConfiguredFailure(kind);
  }

  return (baseUrl: baseUrl, model: model, apiKey: apiKey.trim());
}
