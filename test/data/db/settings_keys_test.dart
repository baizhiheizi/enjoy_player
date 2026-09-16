import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// Key families (dotted prefixes, or the legacy snake_case blobs). Every
/// declared key must belong to one — a key outside all families is usually a
/// typo or a stray declaration nobody owns.
const _knownFamilies = [
  'api.',
  'prefs.',
  'sync.',
  'update.',
  'diagnostics.',
  'analytics.',
  'transcript.',
  'player_',
  'craft.',
  'hotkeys_',
  'ai.',
  'onboarding.',
];

void main() {
  group('SettingsKeys declarations (behavioral invariants)', () {
    test('every declared key is unique', () {
      final names = SettingsKeys.declaredKeys.map((k) => k.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('every declared key belongs to a known family', () {
      for (final key in SettingsKeys.declaredKeys) {
        expect(
          _knownFamilies.any((f) => key.name.startsWith(f)),
          isTrue,
          reason:
              '${key.name} does not start with any known settings family '
              '($_knownFamilies)',
        );
      }
    });

    test('every declared constant is recognized by isKnown', () {
      // The known-key set derives from the same declarations, so this pins
      // the derivation (a hand-rolled side list would drift).
      for (final key in SettingsKeys.declaredKeys) {
        expect(SettingsKeys.isKnown(key.name), isTrue, reason: '$key');
      }
    });

    test('near-miss mutations of declared keys are unknown', () {
      // Exact-match knowledge: a declared name plus any suffix must not be
      // accepted — except declared dynamic-family roots.
      const familyRoots = {'sync.cursor.recording'};
      for (final key in SettingsKeys.declaredKeys.where(
        (k) => !familyRoots.contains(k.name),
      )) {
        expect(SettingsKeys.isKnown('${key.name}.x'), isFalse, reason: '$key');
      }
    });

    test('declared family prefixes do not shadow static keys', () {
      for (final family in SettingsKeys.declaredFamilies) {
        for (final key in SettingsKeys.declaredKeys) {
          expect(
            family.matches(key.name),
            isFalse,
            reason:
                '${key.name} is both a static key and a member of the '
                '${family.prefix} family',
          );
        }
      }
    });
  });

  group('SettingsKeys dynamic helpers', () {
    test('recording-target cursors are distinct per target and known', () {
      final a = SettingsKeys.syncCursorRecordingTarget('Video', 'm-1');
      final b = SettingsKeys.syncCursorRecordingTarget('Video', 'm-2');
      final c = SettingsKeys.syncCursorRecordingTarget('Audio', 'm-1');
      expect(a, isNot(b));
      expect(a, isNot(c));
      expect(SettingsKeys.isKnown(a), isTrue);
      expect(SettingsKeys.isKnown(b), isTrue);
      expect(SettingsKeys.isKnown(c), isTrue);
    });

    test('last-pull cooldown keys are distinct per target and known', () {
      final a = SettingsKeys.syncLastPullAtRecordingTarget('Video', 'm-1');
      final b = SettingsKeys.syncLastPullAtRecordingTarget('Audio', 'm-1');
      expect(a, isNot(b));
      expect(SettingsKeys.isKnown(a), isTrue);
      expect(SettingsKeys.isKnown(b), isTrue);
      // Cursor and cooldown families never collide for the same target.
      expect(a, isNot(SettingsKeys.syncCursorRecordingTarget('Video', 'm-1')));
    });

    test('asr long-form attempt keys are distinct per media and known', () {
      final a = SettingsKeys.asrLongFormAttempt('m-1');
      final b = SettingsKeys.asrLongFormAttempt('m-2');
      expect(a, isNot(b));
      expect(SettingsKeys.isKnown(a), isTrue);
      expect(SettingsKeys.isKnown(b), isTrue);
    });
  });

  group('SettingsKeys.isKnown', () {
    test('recognizes every static key as known', () {
      for (final k in SettingsKeys.declaredKeys) {
        expect(SettingsKeys.isKnown(k.name), isTrue, reason: 'key: ${k.name}');
      }
    });

    test('recognizes sync.cursor.recording.*', () {
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncCursorRecordingTarget('Video', 'x'),
        ),
        isTrue,
      );
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncCursorRecordingTarget('Audio', 'y'),
        ),
        isTrue,
      );
    });

    test('recognizes sync.last_pull_at.recording.*', () {
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncLastPullAtRecordingTarget('Video', 'x'),
        ),
        isTrue,
      );
    });

    test('recognizes asr.long_form.attempt.*', () {
      expect(
        SettingsKeys.isKnown(SettingsKeys.asrLongFormAttempt('m-1')),
        isTrue,
      );
    });

    test('returns false for unknown keys', () {
      expect(SettingsKeys.isKnown('not.a.key'), isFalse);
      expect(SettingsKeys.isKnown('sync.cursor.video.extra'), isFalse);
      expect(SettingsKeys.isKnown('asr.short.attempt.x'), isFalse);
      expect(SettingsKeys.isKnown(''), isFalse);
    });

    test('does NOT match sync.cursor.video with extra suffix', () {
      // Only the recording prefix family is dynamic; video / audio cursors
      // are static and don't open a sub-tree.
      expect(SettingsKeys.isKnown('sync.cursor.video.foo'), isFalse);
      expect(SettingsKeys.isKnown('sync.cursor.audio.foo'), isFalse);
    });
  });

  group('default api origins', () {
    test('kDefaultApiBaseUrl / kDefaultAiApiBaseUrl are stable URLs', () {
      expect(kDefaultApiBaseUrl, 'https://enjoy.bot');
      expect(kDefaultAiApiBaseUrl, 'https://worker.enjoy.bot');
      expect(kDefaultApiBaseUrl.endsWith('/'), isFalse);
      expect(kDefaultAiApiBaseUrl.endsWith('/'), isFalse);
    });

    test('base-url keys default to the canonical origins', () {
      expect(SettingsKeys.apiBaseUrl.defaultValue, kDefaultApiBaseUrl);
      expect(SettingsKeys.apiAiBaseUrl.defaultValue, kDefaultAiApiBaseUrl);
      expect(SettingsKeys.apiBaseUrl.scope, SettingsScope.device);
      expect(SettingsKeys.apiAiBaseUrl.scope, SettingsScope.device);
    });
  });
}
