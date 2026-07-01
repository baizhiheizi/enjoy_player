import 'package:drift/native.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/data/ai_modality_config_repository.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/byok_config_validator.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/modality_provider_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecretStore implements ByokSecretStoreBase {
  @override
  Future<void> deleteApiKey(ModalityKind modality) async {}

  @override
  Future<bool> hasApiKey(ModalityKind modality) async => true;

  @override
  Future<String?> readApiKey(ModalityKind modality) async => 'sk-test1234567890';

  @override
  Future<void> writeApiKey(ModalityKind modality, String apiKey) async {}
}

void main() {
  testWidgets('Remove BYOK shows confirmation dialog', (tester) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.binding.setSurfaceSize(const Size(900, 1200));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          byokSecretStoreProvider.overrideWithValue(_FakeSecretStore()),
          aiModalityConfigRepositoryProvider.overrideWith(
            (ref) => AiModalityConfigRepository(
              db,
              _FakeSecretStore(),
              const ByokConfigValidator(),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModalityProviderCard(
                modality: ModalityKind.llm,
                title: 'Language models',
                subtitle: 'Chat and translation',
                config: AIServiceConfig(
                  provider: AIProvider.byok,
                  llmByok: LlmByokConfig(
                    apiSpec: LlmApiSpec.openAiCompatible,
                    baseUrl: 'https://api.openai.com/v1',
                    model: 'gpt-4o-mini',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Remove BYOK'));
    await tester.tap(find.text('Remove BYOK'));
    await tester.pumpAndSettle();

    expect(find.text('Remove BYOK credentials?'), findsOneWidget);
  });
}
