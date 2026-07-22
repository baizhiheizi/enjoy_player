import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthTokenResponse.fromJson', () {
    test('parses valid response with user', () {
      final r = AuthTokenResponse.fromJson({
        'accessToken': 'at-123',
        'refreshToken': 'rt-456',
        'expiresIn': 3600,
        'tokenType': 'Bearer',
        'user': {'id': '1', 'email': 'a@b.com', 'name': 'Ada'},
      });
      expect(r.accessToken, 'at-123');
      expect(r.refreshToken, 'rt-456');
      expect(r.expiresIn, 3600);
      expect(r.tokenType, 'Bearer');
      expect(r.user, isNotNull);
      expect(r.user!.email, 'a@b.com');
    });

    test('parses response without user', () {
      final r = AuthTokenResponse.fromJson({
        'accessToken': 'at',
        'refreshToken': 'rt',
        'expiresIn': 7200,
      });
      expect(r.user, isNull);
      expect(r.tokenType, 'Bearer');
    });

    test('defaults tokenType to Bearer when absent', () {
      final r = AuthTokenResponse.fromJson({
        'accessToken': 'at',
        'refreshToken': 'rt',
        'expiresIn': 100,
      });
      expect(r.tokenType, 'Bearer');
    });

    test('parses user from non-dynamic Map', () {
      final r = AuthTokenResponse.fromJson({
        'accessToken': 'at',
        'refreshToken': 'rt',
        'expiresIn': 100,
        'user': <Object, Object>{'id': '1', 'email': 'x@y.com', 'name': 'N'},
      });
      expect(r.user, isNotNull);
      expect(r.user!.id, '1');
    });

    test('throws FormatException when accessToken is null', () {
      expect(
        () => AuthTokenResponse.fromJson({
          'refreshToken': 'rt',
          'expiresIn': 100,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when accessToken is empty', () {
      expect(
        () => AuthTokenResponse.fromJson({
          'accessToken': '',
          'refreshToken': 'rt',
          'expiresIn': 100,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when refreshToken is null', () {
      expect(
        () =>
            AuthTokenResponse.fromJson({'accessToken': 'at', 'expiresIn': 100}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when refreshToken is empty', () {
      expect(
        () => AuthTokenResponse.fromJson({
          'accessToken': 'at',
          'refreshToken': '',
          'expiresIn': 100,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when expiresIn is not a num', () {
      expect(
        () => AuthTokenResponse.fromJson({
          'accessToken': 'at',
          'refreshToken': 'rt',
          'expiresIn': 'not-a-number',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when expiresIn is missing', () {
      expect(
        () => AuthTokenResponse.fromJson({
          'accessToken': 'at',
          'refreshToken': 'rt',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OtpSendResponse.fromJson', () {
    test('parses valid response', () {
      final r = OtpSendResponse.fromJson({
        'requestId': 'req-1',
        'expiresIn': 300,
        'resendAfter': 60,
      });
      expect(r.requestId, 'req-1');
      expect(r.expiresIn, 300);
      expect(r.resendAfter, 60);
    });

    test('throws FormatException when requestId is null', () {
      expect(
        () => OtpSendResponse.fromJson({'expiresIn': 300, 'resendAfter': 60}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when requestId is empty', () {
      expect(
        () => OtpSendResponse.fromJson({
          'requestId': '',
          'expiresIn': 300,
          'resendAfter': 60,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when expiresIn is not a num', () {
      expect(
        () => OtpSendResponse.fromJson({
          'requestId': 'req-1',
          'expiresIn': 'abc',
          'resendAfter': 60,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when resendAfter is not a num', () {
      expect(
        () => OtpSendResponse.fromJson({
          'requestId': 'req-1',
          'expiresIn': 300,
          'resendAfter': null,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
