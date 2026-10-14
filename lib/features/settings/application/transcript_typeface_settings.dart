/// Persisted transcript typeface: Book (Literata, default) or Clean (Geist).
///
/// Stored as the [SettingsKeys.transcriptCleanTypeface] device flag.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'transcript_typeface_settings.g.dart';

enum TranscriptTypeface { book, clean }

@Riverpod(keepAlive: true)
class TranscriptTypefaceSettings extends _$TranscriptTypefaceSettings {
  @override
  Future<TranscriptTypeface> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    final clean = await db.settingsDao.readSetting(
      SettingsKeys.transcriptCleanTypeface,
    );
    return clean ? TranscriptTypeface.clean : TranscriptTypeface.book;
  }

  Future<void> select(TranscriptTypeface typeface) async {
    state = await AsyncValue.guard(() async {
      final db = ref.read(deviceGlobalAppDatabaseProvider);
      await db.settingsDao.writeSetting(
        SettingsKeys.transcriptCleanTypeface,
        typeface == TranscriptTypeface.clean,
      );
      return typeface;
    });
  }
}
