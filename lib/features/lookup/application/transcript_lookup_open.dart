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
import 'package:enjoy_player/features/vocabulary/application/media_vocabulary_context_builder.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

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
  final nativeTag = prefs?.effectiveNativeLanguage;
  final echo = ref.read(echoModeProvider);
  final posAsync = ref.read(displayPositionProvider);
  final tSec = switch (posAsync) {
    AsyncData(:final value) => value.inMilliseconds / 1000.0,
    _ => 0.0,
  };

  // Source resolution per spec (FR-005): the video's stored language is the
  // authoritative source — set by the user at import time on VideoRow.language
  // and propagated to PlaybackChrome.language. If the video has no language
  // (`und` / empty), fall back to the active transcript track's language
  // (which is what the user is reading in the panel). If still missing, fall
  // back to the learning language. No sibling-track fallback — picking the
  // "first" track leads to wrong-language lookups when the user has tracks
  // in multiple languages.
  final sourceLang = resolveLookupSourceLanguage(
    chromeLanguage: chrome?.language,
    activeTrackLanguage: _resolveActiveTrackLanguage(ref, chrome?.mediaId),
  );

  final src = resolveLookupSource(sourceLang, learningTag: learnTag);
  final ctx = buildVocabularyContext(
    lines: lines,
    echo: echo,
    currentTimeSeconds: tSec,
    primaryLanguage: src,
  );
  MediaVocabularyContext? mediaCtx;
  final mediaId = chrome?.mediaId;
  final dexieType = chrome?.dexieTargetType;
  if (mediaId != null && dexieType != null) {
    final sourceType = switch (dexieType) {
      'Audio' => VocabularySourceType.audio,
      'Video' => VocabularySourceType.video,
      _ => null,
    };
    if (sourceType != null) {
      mediaCtx = buildMediaVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: tSec,
        primaryLanguage: src,
        sourceType: sourceType,
        sourceId: mediaId,
      );
    }
  }
  final request = LookupRequest(
    selectedText: selectedText,
    sourceLanguage: src,
    targetLanguage: resolveLookupTarget(
      nativeTag,
      learningTag: learnTag,
      sourceLanguage: src,
    ),
    contextualContext: ctx,
    mediaVocabularyContext: mediaCtx,
  );
  unawaited(
    ref.read(lookupCoordinatorProvider.notifier).open(context, request),
  );
  _log.fine(
    'lookup sheet: text="$selectedText" source=$src target=${request.targetLanguage} '
    '(chrome=${chrome?.language ?? "?"} activeTrack=${_resolveActiveTrackLanguage(ref, chrome?.mediaId) ?? "?"} '
    'learn=$learnTag native=$nativeTag)',
  );
}

String? _resolveActiveTrackLanguage(WidgetRef ref, String? mediaId) {
  if (mediaId == null) return null;
  final activeId = ref.read(activeTranscriptIdProvider(mediaId)).valueOrNull;
  if (activeId == null) return null;
  final tracks =
      ref.read(allTranscriptsForMediaProvider(mediaId)).valueOrNull ??
      const <TranscriptTrack>[];
  for (final t in tracks) {
    if (t.id == activeId) return t.language;
  }
  return null;
}

/// Returns the language string to use as the lookup sheet's source.
///
/// Precedence:
/// 1. [chromeLanguage] — the video's stored language (set by the user at
///    import time and propagated to `PlaybackChrome.language`). This is the
///    authoritative source per the lookup spec.
/// 2. [activeTrackLanguage] — the active transcript track's language, used
///    when the video's language is `und` / null / empty (common when the user
///    imported a video without picking a content language but did add a
///    transcript for it).
/// 3. `null` — caller falls back to the learning language via
///    [resolveLookupSource].
///
/// Returns the raw BCP-47 string so the caller can pass it through
/// [resolveLookupSource] with the user's [learningTag].
String? resolveLookupSourceLanguage({
  required String? chromeLanguage,
  required String? activeTrackLanguage,
}) {
  final video = chromeLanguage?.trim() ?? '';
  if (video.isNotEmpty && video != 'und') return video;
  final track = activeTrackLanguage?.trim() ?? '';
  if (track.isNotEmpty && track != 'und') return track;
  return null;
}
