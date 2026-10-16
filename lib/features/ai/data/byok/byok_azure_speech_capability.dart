import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:meta/meta.dart';

/// Azure Speech BYOK plumbing shared across modalities: config, secret store,
/// and SDK handle, with credentials resolved per modality via
/// [resolveCredentials].
abstract base class ByokAzureSpeechCapability {
  ByokAzureSpeechCapability({
    required this._config,
    required this._secrets,
    AzureSpeech? sdk,
  }) : sdk = sdk ?? AzureSpeech.instance;

  final SpeechByokConfig _config;
  final ByokSecretStoreBase _secrets;

  @protected
  SpeechByokConfig get config => _config;

  @protected
  final AzureSpeech sdk;

  Future<AzureSpeechCredentials> resolveCredentials({
    required ModalityKind kind,
    required String capabilityLabel,
  }) {
    return guardAzureSpeechConfig(
      config: _config,
      secrets: _secrets,
      kind: kind,
      capabilityLabel: capabilityLabel,
    );
  }
}
