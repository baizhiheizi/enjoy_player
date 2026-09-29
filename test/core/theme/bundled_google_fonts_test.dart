import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';

const _bundledVariants = [
  'Geist-Regular',
  'Geist-Medium',
  'GeistMono-Medium',
  'InstrumentSerif-Regular',
  'SourceSerif4-Regular',
  'SourceSerif4-Medium',
  'SourceSerif4-SemiBold',
  'PlayfairDisplay-Bold',
  'PlayfairDisplay-SemiBoldItalic',
  'NotoSans-Regular',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every non-CJK variant the app requests resolves from the bundled assets',
    () async {
      final loadErrors = <String>[];
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

      await runZonedGuarded(() async {
        buildAppTheme(Brightness.light);
        buildAppTheme(Brightness.dark);
        GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700);
        GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        );
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
}
