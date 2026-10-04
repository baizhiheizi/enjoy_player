import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/colors.dart';

void main() {
  test('dark overlay uses the Duet ground for the nav bar', () {
    final style = enjoySystemUiOverlayStyle(Brightness.dark);
    expect(style.systemNavigationBarColor, AppColors.groundDark);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarColor, Colors.transparent);
  });

  test('light overlay uses the Duet ground for the nav bar', () {
    final style = enjoySystemUiOverlayStyle(Brightness.light);
    expect(style.systemNavigationBarColor, AppColors.groundLight);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(AppColors.groundLight, const Color(0xFFF5F6F8));
    expect(AppColors.groundDark, const Color(0xFF0E1014));
  });

  testWidgets('AnnotatedRegion follows Theme brightness', (tester) async {
    late SystemUiOverlayStyle captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (context) {
            captured = enjoySystemUiOverlayStyle(Theme.of(context).brightness);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: captured,
              child: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
    expect(captured.systemNavigationBarColor, AppColors.groundLight);
    expect(captured.systemNavigationBarIconBrightness, Brightness.dark);
  });
}
