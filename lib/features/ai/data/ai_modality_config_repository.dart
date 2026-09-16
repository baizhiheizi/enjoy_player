import 'dart:convert';

import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/byok_config_validator.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';

class AiModalityConfigRepository {
  AiModalityConfigRepository(this._db, this._secrets, this._validator);

  final AppDatabase _db;
  final ByokSecretStoreBase _secrets;
  final ByokConfigValidator _validator;

  Future<AiModalityConfigs> load() async {
    final raw = await _db.settingsDao.getValue(
      SettingsKeys.aiModalityConfigsV1.name,
    );
    if (raw == null || raw.isEmpty) {
      return AiModalityConfigs.defaults;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _decodeSnapshot(map);
    } catch (_) {
      return AiModalityConfigs.defaults;
    }
  }

  Future<ByokValidationResult> saveModality({
    required ModalityKind modality,
    required AIServiceConfig config,
    String? apiKey,
  }) async {
    final hasExisting = await _secrets.hasApiKey(modality);
    final validation = _validator.validate(
      modality: modality,
      config: config,
      hasExistingApiKey: hasExisting,
      apiKey: apiKey,
    );
    if (!validation.isValid) return validation;

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _secrets.writeApiKey(modality, apiKey.trim());
    }

    final current = await load();
    final updated = _withModality(current, modality, config);
    await _persist(updated);
    return const ByokValidationResult.valid();
  }

  Future<void> removeByok(ModalityKind modality) async {
    await _secrets.deleteApiKey(modality);
    final current = await load();
    final enjoyOnly = _enjoyConfigFor(modality);
    final updated = _withModality(current, modality, enjoyOnly);
    await _persist(updated);
  }

  Future<bool> hasApiKey(ModalityKind modality) => _secrets.hasApiKey(modality);

  AIServiceConfig _enjoyConfigFor(ModalityKind modality) =>
      const AIServiceConfig(provider: AIProvider.enjoy);

  AiModalityConfigs _withModality(
    AiModalityConfigs configs,
    ModalityKind modality,
    AIServiceConfig config,
  ) {
    final llm = modality == ModalityKind.llm ? config : configs.llm;
    return AiModalityConfigs(
      llm: llm,
      asr: modality == ModalityKind.asr ? config : configs.asr,
      tts: modality == ModalityKind.tts ? config : configs.tts,
      assessment: modality == ModalityKind.assessment
          ? config
          : configs.assessment,
      translation: llm,
      dictionary: llm,
    );
  }

  Future<void> _persist(AiModalityConfigs configs) async {
    final json = _encodeSnapshot(configs);
    await _db.settingsDao.setValue(
      SettingsKeys.aiModalityConfigsV1.name,
      jsonEncode(json),
    );
  }

  Map<String, dynamic> _encodeSnapshot(AiModalityConfigs configs) {
    return {
      ModalityKind.llm.toJsonKey(): _encodeConfig(configs.llm),
      ModalityKind.asr.toJsonKey(): _encodeConfig(configs.asr),
      ModalityKind.tts.toJsonKey(): _encodeConfig(configs.tts),
      ModalityKind.assessment.toJsonKey(): _encodeConfig(configs.assessment),
    };
  }

  Map<String, dynamic> _encodeConfig(AIServiceConfig config) {
    final map = <String, dynamic>{'provider': config.provider.name};
    if (config.provider == AIProvider.byok) {
      if (config.llmByok != null) {
        map['llmByok'] = _encodeLlmByok(config.llmByok!);
      }
      if (config.speechByok != null) {
        map['speechByok'] = _encodeSpeechByok(config.speechByok!);
      }
    }
    return map;
  }

  Map<String, dynamic> _encodeLlmByok(LlmByokConfig config) => {
    'apiSpec': config.apiSpec.toJsonKey(),
    'baseUrl': config.baseUrl,
    'model': config.model,
    if (config.presetId != null) 'presetId': config.presetId,
  };

  Map<String, dynamic> _encodeSpeechByok(SpeechByokConfig config) => {
    'kind': config.kind.toJsonKey(),
    if (config.baseUrl != null) 'baseUrl': config.baseUrl,
    if (config.model != null) 'model': config.model,
    if (config.region != null) 'region': config.region,
    if (config.presetId != null) 'presetId': config.presetId,
  };

  AiModalityConfigs _decodeSnapshot(Map<String, dynamic> map) {
    final llm = _decodeModality(map[ModalityKind.llm.toJsonKey()]);
    return AiModalityConfigs(
      llm: llm,
      asr: _decodeModality(map[ModalityKind.asr.toJsonKey()]),
      tts: _decodeModality(map[ModalityKind.tts.toJsonKey()]),
      assessment: _decodeModality(map[ModalityKind.assessment.toJsonKey()]),
      translation: llm,
      dictionary: llm,
    );
  }

  AIServiceConfig _decodeModality(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const AIServiceConfig(provider: AIProvider.enjoy);
    }

    final providerName = raw['provider'] as String?;
    final provider = AIProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => AIProvider.enjoy,
    );

    LlmByokConfig? llmByok;
    final llmRaw = raw['llmByok'];
    if (llmRaw is Map<String, dynamic>) {
      llmByok = _decodeLlmByok(llmRaw);
    }

    SpeechByokConfig? speechByok;
    final speechRaw = raw['speechByok'];
    if (speechRaw is Map<String, dynamic>) {
      speechByok = _decodeSpeechByok(speechRaw);
    }

    return AIServiceConfig(
      provider: provider,
      llmByok: llmByok,
      speechByok: speechByok,
    );
  }

  LlmByokConfig? _decodeLlmByok(Map<String, dynamic> raw) {
    final apiSpec = LlmApiSpecJson.fromJsonKey(raw['apiSpec'] as String?);
    final baseUrl = raw['baseUrl'] as String?;
    final model = raw['model'] as String?;
    if (apiSpec == null || baseUrl == null || model == null) return null;
    return LlmByokConfig(
      apiSpec: apiSpec,
      baseUrl: baseUrl,
      model: model,
      presetId: raw['presetId'] as String?,
    );
  }

  SpeechByokConfig? _decodeSpeechByok(Map<String, dynamic> raw) {
    final kind = SpeechByokKindJson.fromJsonKey(raw['kind'] as String?);
    if (kind == null) return null;
    return SpeechByokConfig(
      kind: kind,
      baseUrl: raw['baseUrl'] as String?,
      model: raw['model'] as String?,
      region: raw['region'] as String?,
      presetId: raw['presetId'] as String?,
    );
  }
}
