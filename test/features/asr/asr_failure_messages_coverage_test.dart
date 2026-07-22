import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/domain/asr_audio_extraction_failure.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_job_exception.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('asrExtractionMessageKey', () {
    test('maps ffmpegUnavailable', () {
      expect(
        asrExtractionMessageKey(
          AsrAudioExtractionFailureReason.ffmpegUnavailable,
        ),
        'asrErrorFfmpegUnavailable',
      );
    });

    test('maps noAudioTrack', () {
      expect(
        asrExtractionMessageKey(AsrAudioExtractionFailureReason.noAudioTrack),
        'asrErrorNoAudioTrack',
      );
    });

    test('maps ffmpegFailed', () {
      expect(
        asrExtractionMessageKey(AsrAudioExtractionFailureReason.ffmpegFailed),
        'asrErrorExtractionFailed',
      );
    });

    test('maps fileTooLarge', () {
      expect(
        asrExtractionMessageKey(AsrAudioExtractionFailureReason.fileTooLarge),
        'asrErrorFileTooLarge',
      );
    });

    test('maps unsupportedSource', () {
      expect(
        asrExtractionMessageKey(
          AsrAudioExtractionFailureReason.unsupportedSource,
        ),
        'asrErrorUnsupportedSource',
      );
    });
  });

  group('asrLongFormFailureMessageKey', () {
    test('maps billing_exhausted to credits exhausted', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'billing_exhausted',
            retryable: false,
          ),
        ),
        'asrErrorCreditsExhausted',
      );
    });

    test('maps credits_exhausted to credits exhausted', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'credits_exhausted',
            retryable: false,
          ),
        ),
        'asrErrorCreditsExhausted',
      );
    });

    test('maps unsupported_media', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'unsupported_media',
            retryable: false,
          ),
        ),
        'asrErrorUnsupportedMedia',
      );
    });

    test('maps provider_timeout', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'provider_timeout',
            retryable: true,
          ),
        ),
        'asrErrorProviderTimeout',
      );
    });

    test('maps provider_failure retryable to provider retryable', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'provider_failure',
            retryable: true,
          ),
        ),
        'asrErrorProviderRetryable',
      );
    });

    test('maps provider_failure non-retryable to generic', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'provider_failure',
            retryable: false,
          ),
        ),
        'asrErrorGeneric',
      );
    });

    test('maps cancelled to status cancelled', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'cancelled',
            retryable: false,
          ),
        ),
        'asrStatusCancelled',
      );
    });

    test('maps unknown category retryable to provider retryable', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'some_unknown_category',
            retryable: true,
          ),
        ),
        'asrErrorProviderRetryable',
      );
    });

    test('maps unknown category non-retryable to generic', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(
            category: 'some_unknown_category',
            retryable: false,
          ),
        ),
        'asrErrorGeneric',
      );
    });

    test('maps empty category retryable to provider retryable', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(category: '', retryable: true),
        ),
        'asrErrorProviderRetryable',
      );
    });

    test('maps empty category non-retryable to generic', () {
      expect(
        asrLongFormFailureMessageKey(
          const AsrLongFormJobException(category: '', retryable: false),
        ),
        'asrErrorGeneric',
      );
    });
  });

  group('asrPhaseMessageKey', () {
    test('maps idle to empty string', () {
      expect(asrPhaseMessageKey(AsrGenerationPhase.idle), '');
    });

    test('maps extracting', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.extracting),
        'asrStatusExtracting',
      );
    });

    test('maps uploading', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.uploading),
        'asrStatusUploading',
      );
    });

    test('maps recognizing', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.recognizing),
        'asrStatusRecognizing',
      );
    });

    test('maps polling', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.polling),
        'asrStatusPolling',
      );
    });

    test('maps persisting', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.persisting),
        'asrStatusSaving',
      );
    });

    test('maps success', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.success),
        'asrStatusSuccess',
      );
    });

    test('maps error', () {
      expect(asrPhaseMessageKey(AsrGenerationPhase.error), 'asrErrorGeneric');
    });

    test('maps cancelled', () {
      expect(
        asrPhaseMessageKey(AsrGenerationPhase.cancelled),
        'asrStatusCancelled',
      );
    });
  });

  group('asrMessageForKey', () {
    test('resolves asrStatusExtracting', () {
      expect(
        asrMessageForKey(l10n, 'asrStatusExtracting'),
        l10n.asrStatusExtracting,
      );
    });

    test('resolves asrStatusUploading', () {
      expect(
        asrMessageForKey(l10n, 'asrStatusUploading'),
        l10n.asrStatusUploading,
      );
    });

    test('resolves asrStatusRecognizing', () {
      expect(
        asrMessageForKey(l10n, 'asrStatusRecognizing'),
        l10n.asrStatusRecognizing,
      );
    });

    test('resolves asrStatusPolling', () {
      expect(asrMessageForKey(l10n, 'asrStatusPolling'), l10n.asrStatusPolling);
    });

    test('resolves asrStatusSaving', () {
      expect(asrMessageForKey(l10n, 'asrStatusSaving'), l10n.asrStatusSaving);
    });

    test('resolves asrStatusSuccess', () {
      expect(asrMessageForKey(l10n, 'asrStatusSuccess'), l10n.asrStatusSuccess);
    });

    test('resolves asrStatusCancelled', () {
      expect(
        asrMessageForKey(l10n, 'asrStatusCancelled'),
        l10n.asrStatusCancelled,
      );
    });

    test('resolves asrErrorFfmpegUnavailable', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorFfmpegUnavailable'),
        l10n.asrErrorFfmpegUnavailable,
      );
    });

    test('resolves asrErrorNoAudioTrack', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorNoAudioTrack'),
        l10n.asrErrorNoAudioTrack,
      );
    });

    test('resolves asrErrorExtractionFailed', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorExtractionFailed'),
        l10n.asrErrorExtractionFailed,
      );
    });

    test('resolves asrErrorFileTooLarge', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorFileTooLarge'),
        l10n.asrErrorFileTooLarge,
      );
    });

    test('resolves asrErrorUnsupportedSource', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorUnsupportedSource'),
        l10n.asrErrorUnsupportedSource,
      );
    });

    test('resolves asrErrorUnsupportedMedia', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorUnsupportedMedia'),
        l10n.asrErrorUnsupportedMedia,
      );
    });

    test('resolves asrErrorProviderTimeout', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorProviderTimeout'),
        l10n.asrErrorProviderTimeout,
      );
    });

    test('resolves asrErrorProviderRetryable', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorProviderRetryable'),
        l10n.asrErrorProviderRetryable,
      );
    });

    test('resolves asrErrorByokMissing', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorByokMissing'),
        l10n.asrErrorByokMissing,
      );
    });

    test('resolves asrErrorCreditsExhausted', () {
      expect(
        asrMessageForKey(l10n, 'asrErrorCreditsExhausted'),
        l10n.asrErrorCreditsExhausted,
      );
    });

    test('resolves asrErrorNetwork', () {
      expect(asrMessageForKey(l10n, 'asrErrorNetwork'), l10n.asrErrorNetwork);
    });

    test('resolves asrErrorNoSpeech', () {
      expect(asrMessageForKey(l10n, 'asrErrorNoSpeech'), l10n.asrErrorNoSpeech);
    });

    test('resolves asrErrorGeneric', () {
      expect(asrMessageForKey(l10n, 'asrErrorGeneric'), l10n.asrErrorGeneric);
    });

    test('resolves null key to generic error', () {
      expect(asrMessageForKey(l10n, null), l10n.asrErrorGeneric);
    });

    test('resolves unknown key to generic error', () {
      expect(asrMessageForKey(l10n, 'someUnknownKey'), l10n.asrErrorGeneric);
    });

    test('resolves empty string key to generic error', () {
      expect(asrMessageForKey(l10n, ''), l10n.asrErrorGeneric);
    });
  });
}
