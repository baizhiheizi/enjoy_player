/// Persisted user preferences for the transcript blur (practice /
/// listening-focus) feature.
///
/// Mirrors the structure of `PlayerPreferencesCtrl` but for UI prefs.
/// Lazy-hydrates from the Drift `settings` table via `SettingsDao` on
/// first build. Setters mutate state and persist atomically.
///
/// This notifier is `keepAlive: true` so the toggle state survives
/// media-item switches without losing the user's choice.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';

part 'transcript_blur_preferences_provider.g.dart';

final Logger _blurLog = logNamed('transcript_blur.prefs');

@Riverpod(keepAlive: true)
class TranscriptBlurPreferencesCtrl extends _$TranscriptBlurPreferencesCtrl {
  @override
  Future<TranscriptBlurPreferences> build() async {
    final db = ref.watch(appDatabaseProvider);
    final enabledRaw = await db.settingsDao.getValue(
      SettingsKeys.prefsTranscriptBlurPracticeEnabled,
    );
    final secondsRaw = await db.settingsDao.getValue(
      SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
    );

    final enabled = _parseEnabled(enabledRaw);
    final seconds = _parseSeconds(secondsRaw);
    return TranscriptBlurPreferences(
      enabled: enabled,
      tapRevealSeconds: seconds,
    );
  }

  /// Toggles the global blur. Persists to `SettingsDao`. Idempotent.
  Future<void> setEnabled(bool value) async {
    final cur = state.valueOrNull;
    if (cur != null && cur.enabled == value) return;
    state = AsyncData(
      TranscriptBlurPreferences(
        enabled: value,
        tapRevealSeconds:
            cur?.tapRevealSeconds ??
            TranscriptBlurPreferences.tapRevealSecondsDefault,
      ),
    );
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .setValue(
          SettingsKeys.prefsTranscriptBlurPracticeEnabled,
          value ? 'true' : 'false',
        );
  }

  /// Sets the tap-reveal hold duration in seconds. Clamped to
  /// `[tapRevealSecondsMin, tapRevealSecondsMax]`. Values outside the
  /// range are rejected with a warning log and the current value is
  /// kept. Persists on success.
  Future<void> setTapRevealSeconds(int seconds) async {
    final clamped = _clampSeconds(seconds);
    if (clamped != seconds) {
      _blurLog.warning('setTapRevealSeconds: clamped $seconds -> $clamped');
    }
    final cur = state.valueOrNull;
    if (cur != null && cur.tapRevealSeconds == clamped) return;
    state = AsyncData(
      TranscriptBlurPreferences(
        enabled: cur?.enabled ?? false,
        tapRevealSeconds: clamped,
      ),
    );
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .setValue(
          SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
          clamped.toString(),
        );
  }

  static bool _parseEnabled(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    final lower = raw.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    _blurLog.warning('parseEnabled: unrecognized "$raw"; defaulting to false');
    return false;
  }

  static int _parseSeconds(String? raw) {
    if (raw == null || raw.isEmpty) {
      return TranscriptBlurPreferences.tapRevealSecondsDefault;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _blurLog.warning(
        'parseSeconds: unrecognized "$raw"; defaulting to $TranscriptBlurPreferences.tapRevealSecondsDefault',
      );
      return TranscriptBlurPreferences.tapRevealSecondsDefault;
    }
    return _clampSeconds(parsed);
  }

  static int _clampSeconds(int value) {
    if (value < TranscriptBlurPreferences.tapRevealSecondsMin) {
      return TranscriptBlurPreferences.tapRevealSecondsMin;
    }
    if (value > TranscriptBlurPreferences.tapRevealSecondsMax) {
      return TranscriptBlurPreferences.tapRevealSecondsMax;
    }
    return value;
  }
}

/// Read-only projection of the persisted preferences. Useful when a
/// widget only needs to read the current value without ever
/// triggering a setter.
@riverpod
TranscriptBlurPreferences transcriptBlurPreferences(Ref ref) {
  final async = ref.watch(transcriptBlurPreferencesCtrlProvider);
  return async.valueOrNull ?? TranscriptBlurPreferences.defaults;
}
