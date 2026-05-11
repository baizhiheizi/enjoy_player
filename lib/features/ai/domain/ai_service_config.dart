import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/byok_vendor.dart';

part 'ai_service_config.freezed.dart';

@freezed
abstract class BYOKConfig with _$BYOKConfig {
  const factory BYOKConfig({
    required BYOKVendor vendor,
    required String apiKey,
    String? endpoint,
    String? region,
    String? model,
  }) = _BYOKConfig;
}

@freezed
abstract class AIServiceConfig with _$AIServiceConfig {
  const factory AIServiceConfig({
    required AIProvider provider,
    BYOKConfig? byok,
    String? localModelId,
  }) = _AIServiceConfig;
}
