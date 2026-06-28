/// Session tokens returned by `/api/v1/auth/*` success responses.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';

class AuthTokenResponse {
  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'] as String?;
    final refresh = json['refreshToken'] as String?;
    final expiresIn = json['expiresIn'];
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        expiresIn is! num) {
      throw FormatException('Invalid auth token response', json);
    }
    UserProfile? user;
    final userRaw = json['user'];
    if (userRaw is Map<String, dynamic>) {
      user = UserProfile.fromJson(userRaw);
    } else if (userRaw is Map) {
      user = UserProfile.fromJson(
        Map<String, dynamic>.from(
          userRaw.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
    }
    return AuthTokenResponse(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: expiresIn.toInt(),
      tokenType: (json['tokenType'] as String?) ?? 'Bearer',
      user: user,
    );
  }
  const AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final UserProfile? user;
}

class OtpSendResponse {
  factory OtpSendResponse.fromJson(Map<String, dynamic> json) {
    final requestId = json['requestId'] as String?;
    final expiresIn = json['expiresIn'];
    final resendAfter = json['resendAfter'];
    if (requestId == null ||
        requestId.isEmpty ||
        expiresIn is! num ||
        resendAfter is! num) {
      throw FormatException('Invalid OTP send response', json);
    }
    return OtpSendResponse(
      requestId: requestId,
      expiresIn: expiresIn.toInt(),
      resendAfter: resendAfter.toInt(),
    );
  }
  const OtpSendResponse({
    required this.requestId,
    required this.expiresIn,
    required this.resendAfter,
  });

  final String requestId;
  final int expiresIn;
  final int resendAfter;
}
