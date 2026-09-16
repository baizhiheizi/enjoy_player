import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('setEnabled round-trips via SettingsDao', () async {
    final container = ProviderContainer(
      overrides: [deviceGlobalAppDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(karaokeHighlightSettingsProvider.future),
      isFalse,
    );
    await container
        .read(karaokeHighlightSettingsProvider.notifier)
        .setEnabled(true);
    expect(
      await container.read(karaokeHighlightSettingsProvider.future),
      isTrue,
    );
    expect(
      await db.settingsDao.getValue(
        SettingsKeys.transcriptKaraokeHighlight.name,
      ),
      'true',
    );

    await container
        .read(karaokeHighlightSettingsProvider.notifier)
        .setEnabled(false);
    expect(
      await db.settingsDao.readSetting(
        SettingsKeys.transcriptKaraokeHighlight,
      ),
      isFalse,
    );
  });

  test('delayed true is not treated as off after await', () async {
    await db.settingsDao.setValue(
      SettingsKeys.transcriptKaraokeHighlight.name,
      'true',
    );
    final container = ProviderContainer(
      overrides: [deviceGlobalAppDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final loading = container.read(karaokeHighlightSettingsProvider);
    expect(loading.value == false, isFalse);
    expect(
      await container.read(karaokeHighlightSettingsProvider.future),
      isTrue,
    );
    expect(container.read(karaokeHighlightSettingsProvider).value, isTrue);
  });
}
