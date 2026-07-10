import 'package:meta/meta.dart';

/// Parameters for Azure Speech text-to-speech (token or subscription key auth).
@immutable
final class AzureSpeechSynthesisParams {
  const AzureSpeechSynthesisParams({
    required this.text,
    required this.language,
    this.subscriptionKey,
    this.token,
    required this.region,
    this.voice,
  });

  final String text;
  final String language;

  /// Azure subscription key (BYOK path). Mutually exclusive with [token].
  final String? subscriptionKey;

  /// Authorization token from Enjoy worker (`/azure/tokens`).
  /// Mutually exclusive with [subscriptionKey].
  final String? token;

  final String region;
  final String? voice;

  Map<String, Object?> toMap() {
    final hasToken = token != null && token!.isNotEmpty;
    final hasKey = subscriptionKey != null && subscriptionKey!.isNotEmpty;
    if (hasToken == hasKey) {
      throw ArgumentError(
        'Exactly one of token or subscriptionKey must be provided',
      );
    }

    return <String, Object?>{
      'text': text,
      'language': language,
      if (hasKey) 'subscriptionKey': subscriptionKey,
      if (hasToken) 'token': token,
      'region': region,
      if (voice != null && voice!.trim().isNotEmpty) 'voice': voice,
    };
  }
}
