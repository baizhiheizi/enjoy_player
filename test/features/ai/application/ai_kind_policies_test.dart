import 'package:enjoy_player/features/ai/application/ai_kind_policies.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiKindPolicy.isTtlInfinite', () {
    test('is true when ttl is Duration.zero', () {
      const policy = AiKindPolicy(
        ttl: Duration.zero,
        l2RowCap: 100,
        l2AgeCutoff: Duration(days: 1),
      );
      expect(policy.isTtlInfinite, isTrue);
    });

    test('is false for any positive ttl', () {
      const policy = AiKindPolicy(
        ttl: Duration(seconds: 1),
        l2RowCap: 100,
        l2AgeCutoff: Duration(days: 1),
      );
      expect(policy.isTtlInfinite, isFalse);
    });

    test('is false for the default 30-minute ttl', () {
      const policy = AiKindPolicy(
        ttl: Duration(minutes: 30),
        l2RowCap: 100,
        l2AgeCutoff: Duration(days: 1),
      );
      expect(policy.isTtlInfinite, isFalse);
    });
  });

  group('defaultAiKindPolicies', () {
    test('covers every AiKind enum value', () {
      final policies = defaultAiKindPolicies;
      for (final kind in AiKind.values) {
        expect(
          policies,
          contains(kind),
          reason: 'Missing default policy for AiKind.${kind.name}',
        );
      }
    });

    test('translation uses 30 min / 4096 rows / 30 days', () {
      final policies = defaultAiKindPolicies;
      final p = policies[AiKind.translation]!;
      expect(p.ttl, const Duration(minutes: 30));
      expect(p.l2RowCap, 4096);
      expect(p.l2AgeCutoff, const Duration(days: 30));
    });

    test('dictionary uses 30 min / 4096 rows / 30 days', () {
      final policies = defaultAiKindPolicies;
      final p = policies[AiKind.dictionary]!;
      expect(p.ttl, const Duration(minutes: 30));
      expect(p.l2RowCap, 4096);
      expect(p.l2AgeCutoff, const Duration(days: 30));
    });

    test('contextualTranslation uses 30 min / 2048 rows / 14 days', () {
      final policies = defaultAiKindPolicies;
      final p = policies[AiKind.contextualTranslation]!;
      expect(p.ttl, const Duration(minutes: 30));
      expect(p.l2RowCap, 2048);
      expect(p.l2AgeCutoff, const Duration(days: 14));
    });

    test('autoTranslateLine uses 30 min / 8192 rows / 30 days', () {
      final policies = defaultAiKindPolicies;
      final p = policies[AiKind.autoTranslateLine]!;
      expect(p.ttl, const Duration(minutes: 30));
      expect(p.l2RowCap, 8192);
      expect(p.l2AgeCutoff, const Duration(days: 30));
    });

    test('returns a fresh map each invocation', () {
      final first = defaultAiKindPolicies;
      final second = defaultAiKindPolicies;
      expect(identical(first, second), isFalse);
    });

    test('mutating the returned map does not leak into the next call', () {
      final first = defaultAiKindPolicies;
      first.remove(AiKind.translation);
      final second = defaultAiKindPolicies;
      expect(
        second,
        contains(AiKind.translation),
        reason: 'Mutation of one returned map must not affect subsequent calls',
      );
    });

    test('contains exactly the four documented AiKind values', () {
      expect(defaultAiKindPolicies.keys.toSet(), AiKind.values.toSet());
    });
  });
}
