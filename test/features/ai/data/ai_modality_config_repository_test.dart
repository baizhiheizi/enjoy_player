import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/ai_modality_config_repository.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/byok_config_validator.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecretStore implements ByokSecretStoreBase {
  final _keys = <ModalityKind, String>{};

  @override
  Future<void> deleteApiKey(ModalityKind modality) async {
    _keys.remove(modality);
  }

  @override
  Future<bool> hasApiKey(ModalityKind modality) async {
    final value = _keys[modality];
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> readApiKey(ModalityKind modality) async => _keys[modality];

  @override
  Future<void> writeApiKey(ModalityKind modality, String apiKey) async {
    _keys[modality] = apiKey;
  }
}

void main() {
  late AppDatabase db;
  late _FakeSecretStore secrets;
  late AiModalityConfigRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    secrets = _FakeSecretStore();
    repo = AiModalityConfigRepository(db, secrets, const ByokConfigValidator());
  });

  tearDown(() async {
    await db.close();
  });

  test('load returns defaults when Drift key absent', () async {
    final configs = await repo.load();
    expect(configs, AiModalityConfigs.defaults);
  });

  test('saveModality round-trips LLM BYOK without secrets in Drift', () async {
    const config = AIServiceConfig(
      provider: AIProvider.byok,
      llmByok: LlmByokConfig(
        apiSpec: LlmApiSpec.openAiCompatible,
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
        presetId: 'deepseek',
      ),
    );

    final result = await repo.saveModality(
      modality: ModalityKind.llm,
      config: config,
      apiKey: 'sk-secret',
    );
    expect(result.isValid, isTrue);

    final raw = await db.settingsDao.getValue(
      SettingsKeys.aiModalityConfigsV1.name,
    );
    expect(raw, isNotNull);
    expect(raw!, isNot(contains('sk-secret')));
    expect(raw, isNot(contains('apiKey')));

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final llm = map['llm'] as Map<String, dynamic>;
    expect(llm['provider'], 'byok');
    expect(llm['llmByok']['model'], 'deepseek-chat');

    final loaded = await repo.load();
    expect(loaded.llm.provider, AIProvider.byok);
    expect(loaded.llm.llmByok?.model, 'deepseek-chat');
    expect(loaded.translation.provider, AIProvider.byok);
    expect(await secrets.hasApiKey(ModalityKind.llm), isTrue);
  });

  test('removeByok clears secret and resets modality to enjoy', () async {
    await repo.saveModality(
      modality: ModalityKind.assessment,
      config: const AIServiceConfig(
        provider: AIProvider.byok,
        speechByok: SpeechByokConfig(
          kind: SpeechByokKind.azureSpeech,
          region: 'eastus',
        ),
      ),
      apiKey: 'azure-key',
    );

    await repo.removeByok(ModalityKind.assessment);

    final loaded = await repo.load();
    expect(loaded.assessment.provider, AIProvider.enjoy);
    expect(await secrets.hasApiKey(ModalityKind.assessment), isFalse);
  });

  test('removeByok clears secrets for all speech modalities', () async {
    for (final modality in [
      ModalityKind.llm,
      ModalityKind.asr,
      ModalityKind.tts,
    ]) {
      await repo.removeByok(modality);
    }

    for (final modality in ModalityKind.values) {
      expect(await secrets.hasApiKey(modality), isFalse);
    }
  });

  test('saveModality rotates API key when a new key is provided', () async {
    const config = AIServiceConfig(
      provider: AIProvider.byok,
      llmByok: LlmByokConfig(
        apiSpec: LlmApiSpec.openAiCompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
      ),
    );

    await repo.saveModality(
      modality: ModalityKind.llm,
      config: config,
      apiKey: 'sk-old',
    );
    await repo.saveModality(
      modality: ModalityKind.llm,
      config: config,
      apiKey: 'sk-new',
    );

    expect(await secrets.readApiKey(ModalityKind.llm), 'sk-new');
  });

  test('LLM BYOK does not change assessment Enjoy config', () async {
    await repo.saveModality(
      modality: ModalityKind.llm,
      config: const AIServiceConfig(
        provider: AIProvider.byok,
        llmByok: LlmByokConfig(
          apiSpec: LlmApiSpec.openAiCompatible,
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
        ),
      ),
      apiKey: 'sk-test',
    );

    final loaded = await repo.load();
    expect(loaded.llm.provider, AIProvider.byok);
    expect(loaded.assessment.provider, AIProvider.enjoy);
    expect(loaded.asr.provider, AIProvider.enjoy);
  });
}
