import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_configs.dart';
import 'package:enjoy_player/features/ai/data/ai_modality_config_repository.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/byok_config_validator.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  test('controller starts with defaults when Drift key absent', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        aiModalityConfigRepositoryProvider.overrideWith(
          (ref) => AiModalityConfigRepository(
            db,
            _FakeSecretStore(),
            const ByokConfigValidator(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(aiModalityConfigCtrlProvider),
      AiModalityConfigs.defaults,
    );

    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(aiModalityConfigCtrlProvider),
      AiModalityConfigs.defaults,
    );
  });

  test('controller keeps assessment Enjoy when only LLM uses BYOK', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final secrets = _FakeSecretStore();

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        byokSecretStoreProvider.overrideWithValue(secrets),
        aiModalityConfigRepositoryProvider.overrideWith(
          (ref) => AiModalityConfigRepository(
            db,
            secrets,
            const ByokConfigValidator(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);

    final result = await container
        .read(aiModalityConfigCtrlProvider.notifier)
        .saveModality(
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
    expect(result.isValid, isTrue);

    final configs = container.read(aiModalityConfigCtrlProvider);
    expect(configs.llm.provider, AIProvider.byok);
    expect(configs.assessment.provider, AIProvider.enjoy);
    expect(configs.asr.provider, AIProvider.enjoy);
  });
}
