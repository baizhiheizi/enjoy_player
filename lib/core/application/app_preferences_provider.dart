/// App-wide theme, locale, and learner language prefs (Drift-backed).
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';

part 'app_preferences_provider.g.dart';

class AppPreferencesState {
  const AppPreferencesState({
    required this.themeMode,
    required this.locale,
    this.learningLanguage,
    this.nativeLanguage,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final String? learningLanguage;
  final String? nativeLanguage;

  static const initial = AppPreferencesState(
    themeMode: ThemeMode.dark,
    locale: Locale('en'),
    learningLanguage: null,
    nativeLanguage: null,
  );

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? learningLanguage,
    String? nativeLanguage,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
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
    final db = ref.watch(appDatabaseProvider);
    final themeRaw = await db.settingsDao.getValue(SettingsKeys.prefsThemeMode);
    final localeRaw = await db.settingsDao.getValue(SettingsKeys.prefsLocale);
    final learnRaw =
        await db.settingsDao.getValue(SettingsKeys.prefsLearningLanguage);
    final nativeRaw =
        await db.settingsDao.getValue(SettingsKeys.prefsNativeLanguage);

    return AppPreferencesState(
      themeMode: _decodeTheme(themeRaw),
      locale: _decodeLocale(localeRaw),
      learningLanguage: learnRaw?.isEmpty ?? true ? null : learnRaw,
      nativeLanguage: nativeRaw?.isEmpty ?? true ? null : nativeRaw,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final next = (await future).copyWith(themeMode: mode);
    state = AsyncData(next);
    await ref.read(appDatabaseProvider).settingsDao.setValue(
          SettingsKeys.prefsThemeMode,
          _encodeTheme(mode),
        );
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
      themeMode: prev.themeMode,
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

  static ThemeMode _decodeTheme(String? raw) {
    if (raw == null) return ThemeMode.dark;
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static String _encodeTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
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
