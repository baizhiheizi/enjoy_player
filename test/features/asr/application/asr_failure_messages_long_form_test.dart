import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_job_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps long-form failure categories to ARB keys', () {
    expect(
      asrLongFormFailureMessageKey(
        const AsrLongFormJobException(
          category: 'credits_exhausted',
          retryable: false,
        ),
      ),
      'asrErrorCreditsExhausted',
    );
    expect(
      asrLongFormFailureMessageKey(
        const AsrLongFormJobException(
          category: 'billing_exhausted',
          retryable: false,
        ),
      ),
      'asrErrorCreditsExhausted',
    );
    expect(
      asrLongFormFailureMessageKey(
        const AsrLongFormJobException(
          category: 'unsupported_media',
          retryable: false,
        ),
      ),
      'asrErrorUnsupportedMedia',
    );
    expect(
      asrLongFormFailureMessageKey(
        const AsrLongFormJobException(
          category: 'provider_timeout',
          retryable: true,
        ),
      ),
      'asrErrorProviderTimeout',
    );
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

  test('phase keys include uploading and polling', () {
    expect(
      asrPhaseMessageKey(AsrGenerationPhase.uploading),
      'asrStatusUploading',
    );
    expect(asrPhaseMessageKey(AsrGenerationPhase.polling), 'asrStatusPolling');
  });
}
