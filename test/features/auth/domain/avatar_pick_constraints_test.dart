import 'package:enjoy_player/features/auth/domain/avatar_pick_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateAvatarPick', () {
    test('accepts jpeg under 2 MiB', () {
      expect(
        validateAvatarPick(
          byteLength: 1024,
          filename: 'me.jpg',
          contentType: 'image/jpeg',
        ),
        isNull,
      );
    });

    test('rejects empty', () {
      expect(
        validateAvatarPick(byteLength: 0, filename: 'me.jpg'),
        AvatarPickFailure.empty,
      );
    });

    test('rejects oversize', () {
      expect(
        validateAvatarPick(byteLength: kAvatarMaxBytes + 1, filename: 'me.png'),
        AvatarPickFailure.tooLarge,
      );
    });

    test('rejects unsupported type', () {
      expect(
        validateAvatarPick(
          byteLength: 100,
          filename: 'doc.pdf',
          contentType: 'application/pdf',
        ),
        AvatarPickFailure.unsupportedType,
      );
    });

    test('infers content type from filename when mime omitted', () {
      expect(validateAvatarPick(byteLength: 100, filename: 'x.webp'), isNull);
      expect(avatarContentTypeForFilename('x.PNG'), 'image/png');
    });
  });
}
