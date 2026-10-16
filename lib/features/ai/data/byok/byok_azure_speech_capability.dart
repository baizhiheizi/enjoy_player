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
    required this.config,
    required this.secrets,
    AzureSpeech? sdk,
  }) : sdk = sdk ?? AzureSpeech.instance;

  @protected
  final SpeechByokConfig config;

  @protected
  final ByokSecretStoreBase secrets;

  @protected
  final AzureSpeech sdk;

  ModalityKind get kind;

  String get capabilityLabel;

  Future<AzureSpeechCredentials> resolveCredentials() {
    return guardAzureSpeechConfig(
      config: config,
      secrets: secrets,
      kind: kind,
      capabilityLabel: capabilityLabel,
    );
  }
}
