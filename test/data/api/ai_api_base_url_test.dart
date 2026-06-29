import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

/// Regression tests for [AiApiBaseUrl] default behaviour.
///
/// Bug history: `abcdee4` ("perf(ai): … couple AI URL to API URL", #105/#120)
/// changed [AiApiBaseUrl.build] so that, with no persisted `apiAiBaseUrl`
/// override, it returned `apiBaseUrlProvider.future` (the public API
/// origin, `https://enjoy.bot`). That broke every AI route — most visibly
/// `POST /youtube/transcripts`, which is hosted on the worker origin
/// `https://worker.enjoy.bot` and 404s on the public API.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    container = ProviderContainer(
      overrides: [guestAppDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
  });

  test(
    'AiApiBaseUrl defaults to worker origin when no override is persisted',
    () async {
      final resolved = await container.read(aiApiBaseUrlProvider.future);

      expect(resolved, 'https://worker.enjoy.bot');
      // Guard against re-introducing the regression that followed the
      // public API origin instead of the worker origin.
      expect(resolved, isNot('https://enjoy.bot'));
    },
  );

  test(
    'AiApiBaseUrl honours a persisted apiAiBaseUrl override',
    () async {
      await db.settingsDao.setValue(
        SettingsKeys.apiAiBaseUrl,
        'https://ai-staging.example.com',
      );

      final resolved = await container.read(aiApiBaseUrlProvider.future);

      expect(resolved, 'https://ai-staging.example.com');
    },
  );

  test(
    'clearOverride removes the row and rebuilds to the worker default',
    () async {
      // Seed an override so we have something to clear.
      await db.settingsDao.setValue(
        SettingsKeys.apiAiBaseUrl,
        'https://ai-staging.example.com',
      );
      // Eagerly resolve to force the override to be picked up by build().
      expect(
        await container.read(aiApiBaseUrlProvider.future),
        'https://ai-staging.example.com',
      );

      await container
          .read(aiApiBaseUrlProvider.notifier)
          .clearOverride();

      // The persisted row must actually be deleted (not just nulled) —
      // see `SettingsDao.deleteValue`'s contract on `abcdee4`.
      expect(
        await db.settingsDao.getValue(SettingsKeys.apiAiBaseUrl),
        isNull,
      );

      // Force the provider to rebuild so we exercise the no-override branch
      // of `build()` rather than the cached state set by `clearOverride`.
      container.invalidate(aiApiBaseUrlProvider);

      final resolved = await container.read(aiApiBaseUrlProvider.future);
      expect(resolved, 'https://worker.enjoy.bot');
    },
  );
}
