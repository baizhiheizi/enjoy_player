import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_exception.dart';

AppFailure mapApiExceptionToAppFailure(ApiException e) {
  if (e.isUnauthorized) {
    return AuthFailure(e.message);
  }
  if (e.statusCode == 402) {
    return CreditsFailure(e.message);
  }
  return NetworkFailure(e.message, statusCode: e.statusCode);
}
