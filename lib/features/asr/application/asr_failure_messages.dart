/// Maps [AsrAudioExtractionFailureReason] and other ASR failure modes
/// to localized ARB keys consumed by the UI layer.
///
/// The controller is responsible for catching exceptions and looking
/// up the right key. The UI never inspects raw exception types — it
/// only sees the `errorMessage` string on the terminal
/// [AsrGenerationJob].
library;

import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/domain/asr_audio_extraction_failure.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// ARB key for a given extraction failure reason.
String asrExtractionMessageKey(AsrAudioExtractionFailureReason reason) {
  switch (reason) {
    case AsrAudioExtractionFailureReason.ffmpegUnavailable:
      return 'asrErrorFfmpegUnavailable';
    case AsrAudioExtractionFailureReason.noAudioTrack:
      return 'asrErrorNoAudioTrack';
    case AsrAudioExtractionFailureReason.ffmpegFailed:
      return 'asrErrorExtractionFailed';
    case AsrAudioExtractionFailureReason.fileTooLarge:
      return 'asrErrorFileTooLarge';
    case AsrAudioExtractionFailureReason.unsupportedSource:
      return 'asrErrorUnsupportedSource';
  }
}

/// The localized message key for a terminal [AsrGenerationPhase.error]
/// or `cancelled` state. Returns the ARB key, never raw exception text.
String asrPhaseMessageKey(AsrGenerationPhase phase) {
  switch (phase) {
    case AsrGenerationPhase.error:
      return 'asrErrorGeneric';
    case AsrGenerationPhase.cancelled:
      return 'asrStatusCancelled';
    case AsrGenerationPhase.success:
      return 'asrStatusSuccess';
    case AsrGenerationPhase.extracting:
      return 'asrStatusExtracting';
    case AsrGenerationPhase.recognizing:
      return 'asrStatusRecognizing';
    case AsrGenerationPhase.persisting:
      return 'asrStatusSaving';
    case AsrGenerationPhase.idle:
      return '';
  }
}

/// Resolves an ASR message key to localized text at the presentation boundary.
String asrMessageForKey(AppLocalizations l10n, String? key) {
  switch (key) {
    case 'asrStatusExtracting':
      return l10n.asrStatusExtracting;
    case 'asrStatusRecognizing':
      return l10n.asrStatusRecognizing;
    case 'asrStatusSaving':
      return l10n.asrStatusSaving;
    case 'asrStatusSuccess':
      return l10n.asrStatusSuccess;
    case 'asrStatusCancelled':
      return l10n.asrStatusCancelled;
    case 'asrErrorFfmpegUnavailable':
      return l10n.asrErrorFfmpegUnavailable;
    case 'asrErrorNoAudioTrack':
      return l10n.asrErrorNoAudioTrack;
    case 'asrErrorExtractionFailed':
      return l10n.asrErrorExtractionFailed;
    case 'asrErrorFileTooLarge':
      return l10n.asrErrorFileTooLarge;
    case 'asrErrorUnsupportedSource':
      return l10n.asrErrorUnsupportedSource;
    case 'asrErrorByokMissing':
      return l10n.asrErrorByokMissing;
    case 'asrErrorCreditsExhausted':
      return l10n.asrErrorCreditsExhausted;
    case 'asrErrorNetwork':
      return l10n.asrErrorNetwork;
    case 'asrErrorNoSpeech':
      return l10n.asrErrorNoSpeech;
    case 'asrErrorGeneric':
    case null:
      return l10n.asrErrorGeneric;
    default:
      return l10n.asrErrorGeneric;
  }
}
