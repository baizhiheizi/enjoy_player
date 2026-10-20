/// Craft service providers: adapters from the shared AI services to the
/// Craft service interfaces the controller stages depend on.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/craft/data/craft_asr_service_transcriber.dart';
import 'package:enjoy_player/features/craft/data/craft_translation_service_translator.dart';
import 'package:enjoy_player/features/craft/data/craft_tts_service_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/craft_transcriber.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';

/// Provider for the Craft synthesizer (wraps TtsService).
final craftSynthesizerProvider = Provider<CraftSynthesizer>((ref) {
  return CraftTtsServiceSynthesizer(ref.read(ttsServiceProvider));
});

/// Provider for the Craft translator (wraps ChatService / LLM API).
final craftTranslatorProvider = Provider<CraftTranslator>((ref) {
  return CraftTranslationServiceTranslator(ref.read(chatServiceProvider));
});

/// Provider for the Craft transcriber (wraps AsrService).
final craftTranscriberProvider = Provider<CraftTranscriber>((ref) {
  return CraftAsrServiceTranscriber(ref.read(asrServiceProvider));
});
