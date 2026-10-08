import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/typography.dart';

const _bundledVariants = [
  'Geist-Regular',
  'Geist-Medium',
  'Geist-SemiBold',
  'GeistMono-Medium',
  'GeistMono-SemiBold',
  'Literata-Regular',
  'Literata-Medium',
  'Literata-SemiBold',
  'NotoSans-Regular',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> loadErrors;

  setUp(() {
    loadErrors = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {int? wrapWidth}) {
      if (message != null &&
          message.contains('google_fonts was unable to load font')) {
        loadErrors.add(message);
      }
    };
    addTearDown(() {
      debugPrint = originalDebugPrint;
      GoogleFonts.config.allowRuntimeFetching = true;
    });
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test(
    'every variant the app requests resolves from the bundled assets',
    () async {
      await runZonedGuarded(() async {
        buildAppTheme(Brightness.light);
        buildAppTheme(Brightness.dark);
        GoogleFonts.notoSans(fontWeight: FontWeight.w400);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }, (error, stackTrace) {});

      for (final variant in _bundledVariants) {
        final missing = loadErrors
            .where((error) => error.contains('unable to load font $variant '))
            .toList();
        expect(
          missing,
          isEmpty,
          reason:
              '$variant is requested by the theme but did not load from '
              'assets/fonts/google_fonts',
        );
      }
    },
  );

  test(
    'transcript typography requests no unbundled variant in either mode',
    () async {
      final theme = buildAppTheme(Brightness.light);

      await runZonedGuarded(() async {
        for (final useSerif in [true, false]) {
          TranscriptTypographyTokens.build(
            useSerif: useSerif,
            base: theme.textTheme,
            scheme: theme.colorScheme,
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }, (error, stackTrace) {});

      expect(
        loadErrors,
        isEmpty,
        reason:
            'transcript typography must not reach for a runtime-fetched font; '
            'CJK is addressed through fontFamilyFallback names instead',
      );
    },
  );

  test('CJK fallbacks are name-only lookups the platform resolves', () {
    final theme = buildAppTheme(Brightness.light);

    final tokens = TranscriptTypographyTokens.build(
      useSerif: true,
      base: theme.textTheme,
      scheme: theme.colorScheme,
    );

    expect(
      tokens.secondaryStyle.fontFamilyFallback,
      containsAll(kCjkNotoSansFallbacks),
    );
    expect(
      tokens.bodyStyle.fontFamilyFallback,
      containsAll(kCjkNotoSerifFallbacks),
    );
    expect(
      tokens.secondaryStyle.fontFamilyFallback,
      containsAll(kCjkSansFallbacks),
      reason: 'installed-platform CJK faces remain the last resort',
    );
  });
}
