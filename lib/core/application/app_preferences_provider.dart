/// App-wide theme + locale (defaults match prior hard-coded [EnjoyApp] behavior).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppPreferencesState {
  const AppPreferencesState({
    required this.themeMode,
    required this.locale,
  });

  final ThemeMode themeMode;
  final Locale? locale;

  static const initial = AppPreferencesState(
    themeMode: ThemeMode.dark,
    locale: Locale('en'),
  );

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class AppPreferencesCtrl extends Notifier<AppPreferencesState> {
  @override
  AppPreferencesState build() => AppPreferencesState.initial;

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLocale(Locale? locale) {
    state = state.copyWith(locale: locale);
  }
}

final appPreferencesCtrlProvider =
    NotifierProvider<AppPreferencesCtrl, AppPreferencesState>(
      AppPreferencesCtrl.new,
    );
