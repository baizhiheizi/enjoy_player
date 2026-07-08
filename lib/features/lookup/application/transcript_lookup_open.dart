/// Opens the dictionary / translation sheet from transcript selection.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/lookup_coordinator.dart';
import 'package:enjoy_player/features/lookup/application/lookup_target_languages.dart';
import 'package:enjoy_player/features/lookup/application/vocabulary_context_builder.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/all_transcripts_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';

final _log = logNamed('Lookup');

void openTranscriptLookup({
  required WidgetRef ref,
  required BuildContext context,
  required String selectedText,
  required List<TranscriptLine> lines,
}) {
  final chrome = ref.read(playerControllerProvider.select(playbackChromeOf));
  final prefs = ref.read(appPreferencesCtrlProvider).valueOrNull;
  final learnTag =
      prefs?.effectiveLearningLanguage ?? kDefaultLearningLanguageTag;
  final echo = ref.read(echoModeProvider);
  final posAsync = ref.read(displayPositionProvider);
  final tSec = switch (posAsync) {
    AsyncData(:final value) => value.inMilliseconds / 1000.0,
    _ => 0.0,
  };

  final mediaId = chrome?.mediaId;
  TranscriptTrack? activeTrack;
  List<TranscriptTrack> allTracks = const <TranscriptTrack>[];
  if (mediaId != null) {
    final activeId = ref.read(activeTranscriptIdProvider(mediaId)).valueOrNull;
    allTracks =
        ref.read(allTranscriptsForMediaProvider(mediaId)).valueOrNull ??
        const <TranscriptTrack>[];
    if (activeId != null) {
      for (final t in allTracks) {
        if (t.id == activeId) {
          activeTrack = t;
          break;
        }
      }
    }
  }

  // The active track is the user's currently selected primary. If its language
  // metadata is missing (`und` / null / empty) — common for embedded subtitle
  // streams in MP4 / MKV files without language tags — fall back to the first
  // sibling track whose language is a valid lookup-catalog tag. This prevents
  // the lookup sheet from silently defaulting to the learning language when
  // the user is reading Korean / Japanese / Spanish / etc. content that the
  // player has no explicit language metadata for.
  final sourceLang = resolveLookupSourceLanguage(
    activeTrack: activeTrack,
    allTracks: allTracks,
  );
  if (sourceLang != activeTrack?.language) {
    _log.info(
      'lookup active track has no language '
      '(id=${activeTrack?.id ?? "none"} lang="${activeTrack?.language ?? ""}"); '
      'using sibling track lang=$sourceLang',
    );
  }

  final src = resolveLookupSource(sourceLang, learningTag: learnTag);
  final ctx = buildVocabularyContext(
    lines: lines,
    echo: echo,
    currentTimeSeconds: tSec,
    primaryLanguage: src,
  );
  final request = LookupRequest(
    selectedText: selectedText,
    sourceLanguage: src,
    targetLanguage: resolveLookupTarget(
      prefs?.nativeLanguage,
      learningTag: learnTag,
    ),
    contextualContext: ctx,
  );
  unawaited(
    ref.read(lookupCoordinatorProvider.notifier).open(context, request),
  );
}

/// Returns the first [TranscriptTrack] in [tracks] whose `language` resolves to
/// a tag in [kSupportedLookupLanguageTags] (full or primary-subtag match), or
/// `null` if none qualifies.
TranscriptTrack? firstLookupCatalogTrack(List<TranscriptTrack> tracks) {
  for (final t in tracks) {
    final lang = t.language.trim();
    if (lang.isEmpty || lang == 'und') continue;
    final resolved = resolveLookupSource(
      lang,
      learningTag: kDefaultLearningLanguageTag,
    );
    if (resolved != kDefaultLearningLanguageTag) return t;
  }
  return null;
}

/// Returns the language string to use as the lookup sheet's source.
///
/// Prefers [activeTrack]?.language when it is a usable (non-empty, non-`und`)
/// value; otherwise falls back to the first sibling track in [allTracks] that
/// has a valid lookup-catalog language. Returns the raw track language so the
/// caller can pass it through [resolveLookupSource] with the user's
/// [learningTag].
String? resolveLookupSourceLanguage({
  required TranscriptTrack? activeTrack,
  required List<TranscriptTrack> allTracks,
}) {
  final activeLang = activeTrack?.language.trim() ?? '';
  if (activeLang.isNotEmpty && activeLang != 'und') {
    return activeLang;
  }
  final fallback = firstLookupCatalogTrack(allTracks);
  if (fallback != null && fallback.id != activeTrack?.id) return fallback.language;
  return activeTrack?.language;
}
