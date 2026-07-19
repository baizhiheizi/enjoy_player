/// DTOs for Worker long-form transcription jobs (Deepgram path).
library;

import 'package:enjoy_player/core/json/json_cast.dart';

enum AsrLongFormJobStatus {
  accepted,
  processing,
  completed,
  failed,
  unknown;

  static AsrLongFormJobStatus parse(String? raw) {
    switch (raw) {
      case 'accepted':
        return AsrLongFormJobStatus.accepted;
      case 'processing':
        return AsrLongFormJobStatus.processing;
      case 'completed':
        return AsrLongFormJobStatus.completed;
      case 'failed':
        return AsrLongFormJobStatus.failed;
      default:
        return AsrLongFormJobStatus.unknown;
    }
  }

  bool get isTerminal =>
      this == AsrLongFormJobStatus.completed ||
      this == AsrLongFormJobStatus.failed;

  bool get isPending =>
      this == AsrLongFormJobStatus.accepted ||
      this == AsrLongFormJobStatus.processing;
}

final class AsrLongFormFailure {
  const AsrLongFormFailure({
    required this.category,
    required this.retryable,
    this.message,
  });

  factory AsrLongFormFailure.fromJson(Map<String, dynamic> json) {
    return AsrLongFormFailure(
      category: json['category'] as String? ?? 'provider_failure',
      retryable: json['retryable'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  final String category;
  final bool retryable;
  final String? message;
}

final class AsrLongFormUsage {
  const AsrLongFormUsage({
    required this.actualDurationSeconds,
    required this.creditsCharged,
  });

  factory AsrLongFormUsage.fromJson(Map<String, dynamic> json) {
    return AsrLongFormUsage(
      actualDurationSeconds:
          (json['actualDurationSeconds'] as num?)?.toDouble() ??
          (json['actual_duration_seconds'] as num?)?.toDouble() ??
          0,
      creditsCharged:
          (json['creditsCharged'] as num?)?.toInt() ??
          (json['credits_charged'] as num?)?.toInt() ??
          0,
    );
  }

  final double actualDurationSeconds;
  final int creditsCharged;
}

final class AsrLongFormTranscript {
  const AsrLongFormTranscript({
    required this.text,
    this.language,
    this.actualDurationSeconds,
    this.segments = const [],
    this.words = const [],
    this.provider,
    this.model,
  });

  factory AsrLongFormTranscript.fromJson(Map<String, dynamic> json) {
    final segs = json['segments'] as List<dynamic>?;
    final words = json['words'] as List<dynamic>?;
    return AsrLongFormTranscript(
      text: json['text'] as String? ?? '',
      language: json['language'] as String?,
      actualDurationSeconds:
          (json['actualDurationSeconds'] as num?)?.toDouble() ??
          (json['actual_duration_seconds'] as num?)?.toDouble(),
      segments:
          segs
              ?.map((e) => castJsonObjectOrNull(e))
              .whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
      words:
          words
              ?.map((e) => castJsonObjectOrNull(e))
              .whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
      provider: json['provider'] as String?,
      model: json['model'] as String?,
    );
  }

  final String text;
  final String? language;
  final double? actualDurationSeconds;
  final List<Map<String, dynamic>> segments;
  final List<Map<String, dynamic>> words;
  final String? provider;
  final String? model;
}

final class AsrLongFormJob {
  const AsrLongFormJob({
    required this.jobId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.failure,
    this.usage,
    this.transcript,
  });

  factory AsrLongFormJob.fromJson(Map<String, dynamic> json) {
    final failureMap = castJsonObjectOrNull(json['failure']);
    final usageMap = castJsonObjectOrNull(json['usage']);
    final transcriptMap = castJsonObjectOrNull(json['transcript']);
    return AsrLongFormJob(
      jobId: json['jobId'] as String? ?? json['job_id'] as String? ?? '',
      status: AsrLongFormJobStatus.parse(json['status'] as String?),
      createdAt: _parseTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseTime(json['updatedAt'] ?? json['updated_at']),
      completedAt: _parseTime(json['completedAt'] ?? json['completed_at']),
      failure: failureMap == null
          ? null
          : AsrLongFormFailure.fromJson(failureMap),
      usage: usageMap == null ? null : AsrLongFormUsage.fromJson(usageMap),
      transcript: transcriptMap == null
          ? null
          : AsrLongFormTranscript.fromJson(transcriptMap),
    );
  }

  final String jobId;
  final AsrLongFormJobStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final AsrLongFormFailure? failure;
  final AsrLongFormUsage? usage;
  final AsrLongFormTranscript? transcript;

  static DateTime? _parseTime(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

/// Local in-flight long-form attempt metadata (JSON-serializable).
final class AsrLongFormAttempt {
  const AsrLongFormAttempt({
    required this.mediaId,
    required this.idempotencyKey,
    required this.declaredDurationSeconds,
    required this.startedAt,
    this.jobId,
    this.language,
    this.mediaReference,
  });

  factory AsrLongFormAttempt.fromJson(Map<String, dynamic> json) {
    return AsrLongFormAttempt(
      mediaId: json['mediaId'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      jobId: json['jobId'] as String?,
      language: json['language'] as String?,
      declaredDurationSeconds:
          (json['declaredDurationSeconds'] as num?)?.toDouble() ?? 0,
      mediaReference: json['mediaReference'] as String?,
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String mediaId;
  final String idempotencyKey;
  final String? jobId;
  final String? language;
  final double declaredDurationSeconds;
  final String? mediaReference;
  final DateTime startedAt;

  Map<String, dynamic> toJson() => {
    'mediaId': mediaId,
    'idempotencyKey': idempotencyKey,
    if (jobId != null) 'jobId': jobId,
    if (language != null) 'language': language,
    'declaredDurationSeconds': declaredDurationSeconds,
    if (mediaReference != null) 'mediaReference': mediaReference,
    'startedAt': startedAt.toIso8601String(),
  };

  AsrLongFormAttempt copyWith({String? jobId, String? mediaReference}) {
    return AsrLongFormAttempt(
      mediaId: mediaId,
      idempotencyKey: idempotencyKey,
      jobId: jobId ?? this.jobId,
      language: language,
      declaredDurationSeconds: declaredDurationSeconds,
      mediaReference: mediaReference ?? this.mediaReference,
      startedAt: startedAt,
    );
  }
}
