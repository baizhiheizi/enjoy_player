import 'dart:typed_data';

import 'package:enjoy_player/features/ai/domain/models/asr_long_form_phase.dart';

/// Request for worker `POST /audio/transcriptions` (OpenAI-compatible).
final class AsrRequest {
  const AsrRequest({
    required this.audioBytes,
    required this.filename,
    this.mimeType,
    this.model,
    this.language,
    this.prompt,
    this.responseFormat = 'json',
    this.durationSeconds,
    this.idempotencyKey,
    this.existingJobId,
    this.existingMediaReference,
    this.onLongFormPhase,
    this.onLongFormUploaded,
    this.onLongFormJobAccepted,
    this.shouldCancel,
  });

  final Uint8List audioBytes;
  final String filename;
  final String? mimeType;
  final String? model;
  final String? language;
  final String? prompt;

  /// `json` | `text` | `vtt`
  final String responseFormat;
  final double? durationSeconds;

  /// Required for Enjoy long-form (≥900s); reused on transport retry.
  final String? idempotencyKey;

  /// When set, skip upload/submit and poll this job (resume).
  final String? existingJobId;

  /// When set with [idempotencyKey], skip upload and re-submit idempotently.
  final String? existingMediaReference;

  /// Optional progress hook for Enjoy long-form upload/poll phases.
  final void Function(AsrLongFormClientPhase phase)? onLongFormPhase;

  /// Called after media upload succeeds so the client can persist the reference.
  final void Function(String mediaReference)? onLongFormUploaded;

  /// Called after submit accepts a job so the client can persist resume state.
  final void Function(String jobId, String mediaReference)?
  onLongFormJobAccepted;

  /// When true, long-form polling/upload should abort.
  final bool Function()? shouldCancel;
}
