import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/profile_identity.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(Brightness.dark),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('the identity row renders the avatar, name and secondary line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsProfileIdentityRow(
          name: 'Reader',
          secondaryText: 'reader@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AccountAvatar), findsOneWidget);
    expect(find.text('Reader'), findsOneWidget);
    expect(find.text('reader@example.com'), findsOneWidget);
  });

  testWidgets('the trailing slot renders next to the identity text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsProfileIdentityRow(
          name: 'Reader',
          secondaryText: 'reader@example.com',
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('the name uses the titleMedium size with the bold weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsProfileIdentityRow(
          name: 'Reader',
          secondaryText: 'reader@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(find.text('Reader'));
    final secondary = tester.widget<Text>(find.text('reader@example.com'));

    expect(name.style?.fontSize, 15);
    expect(name.style?.fontWeight, FontWeight.w600);
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(secondary.style?.fontSize, 13);
    expect(secondary.maxLines, 1);
    expect(secondary.overflow, TextOverflow.ellipsis);
  });
}
