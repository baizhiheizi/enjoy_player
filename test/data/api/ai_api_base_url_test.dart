import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

/// Regression tests for [AiApiBaseUrl] default behaviour.
///
/// With no persisted `apiAiBaseUrl` override, [AiApiBaseUrl.build] resolves to
/// [kDefaultAiApiBaseUrl] (`https://enjoy.bot`), and persisted overrides +
/// `clearOverride()` continue to work independently.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    container = ProviderContainer(
      overrides: [deviceGlobalAppDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
  });

  test(
    'AiApiBaseUrl defaults to kDefaultAiApiBaseUrl when no override is persisted',
    () async {
      final resolved = await container.read(aiApiBaseUrlProvider.future);

      expect(resolved, 'https://enjoy.bot');
      expect(resolved, kDefaultAiApiBaseUrl);
    },
  );

  test('AiApiBaseUrl honours a persisted apiAiBaseUrl override', () async {
    await db.settingsDao.setValue(
      SettingsKeys.apiAiBaseUrl.name,
      'https://ai-staging.example.com',
    );

    final resolved = await container.read(aiApiBaseUrlProvider.future);

    expect(resolved, 'https://ai-staging.example.com');
  });

  test(
    'AiApiBaseUrl migrates persisted legacy worker.enjoy.bot override to enjoy.bot',
    () async {
      await db.settingsDao.setValue(
        SettingsKeys.apiAiBaseUrl.name,
        'https://worker.enjoy.bot/',
      );

      final resolved = await container.read(aiApiBaseUrlProvider.future);

      expect(resolved, 'https://enjoy.bot');
    },
  );

  test(
    'clearOverride removes the row and rebuilds to the unified default',
    () async {
      await db.settingsDao.setValue(
        SettingsKeys.apiAiBaseUrl.name,
        'https://ai-staging.example.com',
      );
      expect(
        await container.read(aiApiBaseUrlProvider.future),
        'https://ai-staging.example.com',
      );

      await container.read(aiApiBaseUrlProvider.notifier).clearOverride();

      expect(
        await db.settingsDao.getValue(SettingsKeys.apiAiBaseUrl.name),
        isNull,
      );

      container.invalidate(aiApiBaseUrlProvider);

      final resolved = await container.read(aiApiBaseUrlProvider.future);
      expect(resolved, 'https://enjoy.bot');
    },
  );
}
