import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('parses mixinId when present', () {
      final p = UserProfile.fromJson({
        'id': '24000001',
        'email': 'a@b.com',
        'name': 'Ada',
        'mixinId': '12345678',
        'hasMixin': true,
      });
      expect(p.id, '24000001');
      expect(p.mixinId, '12345678');
      expect(p.hasMixin, isTrue);
    });

    test('leaves mixinId null when absent', () {
      final p = UserProfile.fromJson({
        'id': '24000001',
        'email': 'a@b.com',
        'name': 'Ada',
        'hasMixin': false,
      });
      expect(p.mixinId, isNull);
    });

    test('round-trips mixinId through toJson', () {
      const original = UserProfile(
        id: '1',
        email: 'e@x.com',
        name: 'N',
        mixinId: '99',
      );
      final again = UserProfile.fromJson(original.toJson());
      expect(again.mixinId, '99');
    });
  });
}
