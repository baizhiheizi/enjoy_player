/// App-wide locale and learner language prefs (Drift-backed).
library;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';

part 'app_preferences_provider.g.dart';

final Logger _prefsLog = logNamed('prefs');

class AppPreferencesState {
  const AppPreferencesState({
    required this.locale,
    this.learningLanguage,
    this.nativeLanguage,
  });

  final Locale? locale;
  final String? learningLanguage;
  final String? nativeLanguage;

  static const initial = AppPreferencesState(
    locale: Locale('en'),
    learningLanguage: null,
    nativeLanguage: null,
  );

  AppPreferencesState copyWith({
    Locale? locale,
    String? learningLanguage,
    String? nativeLanguage,
  }) {
    return AppPreferencesState(
      locale: locale ?? this.locale,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
    );
  }
}

@Riverpod(keepAlive: true)
class AppPreferencesCtrl extends _$AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async {
    final sw = Stopwatch()..start();
    _prefsLog.info('prefs: build start');
    final db = ref.watch(appDatabaseProvider);
    final localeRaw = await db.settingsDao.getValue(SettingsKeys.prefsLocale);
    final learnRaw =
        await db.settingsDao.getValue(SettingsKeys.prefsLearningLanguage);
    final nativeRaw =
        await db.settingsDao.getValue(SettingsKeys.prefsNativeLanguage);

    final out = AppPreferencesState(
      locale: _decodeLocale(localeRaw),
      learningLanguage: learnRaw?.isEmpty ?? true ? null : learnRaw,
      nativeLanguage: nativeRaw?.isEmpty ?? true ? null : nativeRaw,
    );
    _prefsLog.info('prefs: build done in ${sw.elapsedMilliseconds}ms');
    return out;
  }

  Future<void> setLocale(Locale? locale) async {
    final next = (await future).copyWith(locale: locale);
    state = AsyncData(next);
    final tag = locale?.toLanguageTag() ?? 'en';
    await ref.read(appDatabaseProvider).settingsDao.setValue(
          SettingsKeys.prefsLocale,
          tag,
        );
  }

  /// Server wins for locale + languages on login / profile refresh.
  Future<void> applyFromUserProfile(UserProfile profile) async {
    final prev = await future;
    Locale? nextLocale = prev.locale;
    if (profile.locale != null && profile.locale!.trim().isNotEmpty) {
      nextLocale = _decodeLocale(profile.locale);
    }
    final next = AppPreferencesState(
      locale: nextLocale,
      learningLanguage: profile.learningLanguage ?? prev.learningLanguage,
      nativeLanguage: profile.nativeLanguage ?? prev.nativeLanguage,
    );
    state = AsyncData(next);
    final db = ref.read(appDatabaseProvider);
    await db.settingsDao.setValue(
      SettingsKeys.prefsLocale,
      nextLocale?.toLanguageTag() ?? 'en',
    );
    if (profile.learningLanguage != null) {
      await db.settingsDao.setValue(
        SettingsKeys.prefsLearningLanguage,
        profile.learningLanguage!,
      );
    }
    if (profile.nativeLanguage != null) {
      await db.settingsDao.setValue(
        SettingsKeys.prefsNativeLanguage,
        profile.nativeLanguage!,
      );
    }
  }

  static Locale _decodeLocale(String? raw) {
    if (raw == null || raw.isEmpty) return const Locale('en');
    final parts = raw.split(RegExp(r'[-_]'));
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(raw);
  }
}
