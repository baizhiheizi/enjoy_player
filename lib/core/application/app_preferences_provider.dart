/// App-wide locale and learner language prefs (Drift-backed).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';

export 'package:enjoy_player/core/application/app_language_catalog.dart'
    show kAppDefaultDisplayLocale;

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
    locale: kAppDefaultDisplayLocale,
    learningLanguage: null,
    nativeLanguage: null,
  );

  /// MVP: learning is always English (US).
  String get effectiveLearningLanguage => kDefaultLearningLanguageTag;

  /// Native tag for UX and APIs; never equals [effectiveLearningLanguage].
  String get effectiveNativeLanguage =>
      coerceNativeIfEqualsLearning(nativeLanguage, effectiveLearningLanguage);

  Locale get effectiveDisplayLocale => locale ?? kAppDefaultDisplayLocale;

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
  String? _lastAppliedProfileSignature;

  @override
  Future<AppPreferencesState> build() async {
    final sw = Stopwatch()..start();
    _prefsLog.info('prefs: build start');
    final db = ref.watch(appDatabaseProvider);
    var localeRaw = await db.settingsDao.getValue(SettingsKeys.prefsLocale);
    var learnRaw = await db.settingsDao.getValue(
      SettingsKeys.prefsLearningLanguage,
    );
    var nativeRaw = await db.settingsDao.getValue(
      SettingsKeys.prefsNativeLanguage,
    );

    final learnCanonical = kDefaultLearningLanguageTag;
    if (learnRaw == null ||
        learnRaw.isEmpty ||
        !tagsEqual(learnRaw, learnCanonical)) {
      await db.settingsDao.setValue(
        SettingsKeys.prefsLearningLanguage,
        learnCanonical,
      );
      learnRaw = learnCanonical;
    }

    final nativeCoerced = coerceNativeIfEqualsLearning(
      nativeRaw,
      learnCanonical,
    );
    if (nativeRaw == null ||
        nativeRaw.isEmpty ||
        !tagsEqual(nativeRaw, nativeCoerced)) {
      await db.settingsDao.setValue(
        SettingsKeys.prefsNativeLanguage,
        nativeCoerced,
      );
      nativeRaw = nativeCoerced;
    }

    final decodedLocale = displayLocaleFromRawOrDefault(localeRaw);
    final canonicalLocaleTag = localeToBcp47(decodedLocale);
    if (localeRaw == null ||
        localeRaw.isEmpty ||
        !tagsEqual(canonicalLocaleTag, localeRaw)) {
      await db.settingsDao.setValue(
        SettingsKeys.prefsLocale,
        canonicalLocaleTag,
      );
      localeRaw = canonicalLocaleTag;
    }

    final out = AppPreferencesState(
      locale: decodedLocale,
      learningLanguage: learnCanonical,
      nativeLanguage: nativeCoerced,
    );

    // Apply server-side prefs on sign-in / profile refresh (was previously
    // pushed from AuthCtrl, which created a Riverpod cycle).
    ref.listen(authCtrlProvider, (previous, next) {
      final v = next.valueOrNull;
      if (v is! AuthSignedIn) {
        _lastAppliedProfileSignature = null;
        return;
      }
      final sig = _profileSignature(v.profile);
      if (sig == _lastAppliedProfileSignature) return;
      _lastAppliedProfileSignature = sig;
      // Defer so we don't mutate state mid-listener.
      unawaited(Future<void>.microtask(() => applyFromUserProfile(v.profile)));
    }, fireImmediately: true);

    _prefsLog.info('prefs: build done in ${sw.elapsedMilliseconds}ms');
    return out;
  }

  static String _profileSignature(UserProfile p) =>
      '${p.id}|${p.locale ?? ''}|${p.learningLanguage ?? ''}|${p.nativeLanguage ?? ''}';

  Future<void> setLocale(Locale? locale) async {
    final resolved = locale == null
        ? kAppDefaultDisplayLocale
        : displayLocaleFromRawOrDefault(localeToBcp47(locale));
    final next = (await future).copyWith(locale: resolved);
    state = AsyncData(next);
    final tag = localeToBcp47(resolved);
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .setValue(SettingsKeys.prefsLocale, tag);
    await ref
        .read(authCtrlProvider.notifier)
        .syncLocaleToServerIfSignedIn(resolved);
  }

  Future<void> setNativeLanguage(String tag) async {
    final learn = kDefaultLearningLanguageTag;
    final allowed = allowedNativeTags(learn);
    if (!allowed.any((t) => tagsEqual(t, tag))) {
      _prefsLog.warning('prefs: rejected native language tag: $tag');
      return;
    }
    final canonical = allowed.firstWhere(
      (t) => tagsEqual(t, tag),
      orElse: () => tag,
    );
    if (tagsEqual(canonical, learn)) return;

    final next = (await future).copyWith(nativeLanguage: canonical);
    state = AsyncData(next);
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .setValue(SettingsKeys.prefsNativeLanguage, canonical);
    await _syncLanguageFieldsToServerIfSignedIn(
      learningLanguage: learn,
      nativeLanguage: canonical,
    );
  }

  /// Ensures Drift + (when signed in) server use canonical learning + coerced native.
  Future<void> applyFromUserProfile(UserProfile profile) async {
    final prev = await future;
    Locale? nextLocale = prev.locale;
    if (profile.locale != null && profile.locale!.trim().isNotEmpty) {
      nextLocale = displayLocaleFromRawOrDefault(profile.locale);
    }

    final learnCanonical = kDefaultLearningLanguageTag;
    final nativeCoerced = coerceNativeIfEqualsLearning(
      profile.nativeLanguage ?? prev.nativeLanguage,
      learnCanonical,
    );

    final next = AppPreferencesState(
      locale: nextLocale,
      learningLanguage: learnCanonical,
      nativeLanguage: nativeCoerced,
    );
    state = AsyncData(next);
    final db = ref.read(appDatabaseProvider);
    await db.settingsDao.setValue(
      SettingsKeys.prefsLocale,
      localeToBcp47(nextLocale ?? kAppDefaultDisplayLocale),
    );
    await db.settingsDao.setValue(
      SettingsKeys.prefsLearningLanguage,
      learnCanonical,
    );
    await db.settingsDao.setValue(
      SettingsKeys.prefsNativeLanguage,
      nativeCoerced,
    );

    final serverLearn = profile.learningLanguage;
    final serverNative = profile.nativeLanguage;
    final needsPatchLearn =
        serverLearn != null && !tagsEqual(serverLearn, learnCanonical);
    final needsPatchNative =
        serverNative != null && !tagsEqual(serverNative, nativeCoerced);
    if (needsPatchLearn || needsPatchNative) {
      await _syncLanguageFieldsToServerIfSignedIn(
        learningLanguage: learnCanonical,
        nativeLanguage: nativeCoerced,
      );
    }
  }

  Future<void> _syncLanguageFieldsToServerIfSignedIn({
    String? learningLanguage,
    String? nativeLanguage,
  }) async {
    final cur = ref.read(authCtrlProvider).valueOrNull;
    if (cur is! AuthSignedIn) return;
    await ref
        .read(authCtrlProvider.notifier)
        .updateProfile(
          UpdateProfileRequest(
            learningLanguage: learningLanguage,
            nativeLanguage: nativeLanguage,
          ),
        );
  }
}
