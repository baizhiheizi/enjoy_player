/// Isolated-test overrides so transcript tiles never open SettingsDao.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/settings/application/transcript_typeface_settings.dart';

class IpaOverlaySettingsOverride extends IpaOverlaySettings {
  IpaOverlaySettingsOverride(this.enabled);

  final bool enabled;

  @override
  Future<bool> build() async => enabled;
}

class KaraokeHighlightSettingsOverride extends KaraokeHighlightSettings {
  KaraokeHighlightSettingsOverride(this.enabled);

  final bool enabled;

  @override
  Future<bool> build() async => enabled;
}

/// Default-off IPA for existing tile tests (karaoke / blur / lookup).
List<Override> transcriptIpaOverlayOffOverrides() => [
  ipaOverlaySettingsProvider.overrideWith(
    () => IpaOverlaySettingsOverride(false),
  ),
];

/// Alias kept so older call sites still compile during the IPA UX migrate.
List<Override> transcriptWordPracticeOffOverrides() =>
    transcriptIpaOverlayOffOverrides();

List<Override> transcriptIpaOverlayOnOverrides() => [
  ipaOverlaySettingsProvider.overrideWith(
    () => IpaOverlaySettingsOverride(true),
  ),
];

class TranscriptTypefaceSettingsOverride extends TranscriptTypefaceSettings {
  TranscriptTypefaceSettingsOverride([this.initial = TranscriptTypeface.book]);

  final TranscriptTypeface initial;

  @override
  Future<TranscriptTypeface> build() async => initial;

  @override
  Future<void> select(TranscriptTypeface typeface) async {
    state = AsyncData(typeface);
  }
}
