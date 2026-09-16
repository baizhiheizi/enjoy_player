import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/appearance_language_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/cloud_sync_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _fakeProfile = UserProfile(
  id: 'user-1',
  email: 'reader@example.com',
  name: 'Reader',
);

class _NeverPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() =>
      Completer<AppPreferencesState>().future;
}

class _SignedInAuthCtrlForSyncLoading extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _fakeProfile);
}

// ignore: strict_top_level_inference
Widget _harness(Widget child, {overrides = const []}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      locale: const Locale('en', 'US'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets(
    'a loading language-prefs row renders skeleton lines, not a blank body',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          const AppearanceLanguageSectionBody(),
          overrides: [
            appPreferencesCtrlProvider.overrideWith(_NeverPrefsCtrl.new),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Skeleton), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a loading sync queue snapshot renders a skeleton value badge, not a '
    'blank row',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          const CloudSyncSectionBody(),
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrlForSyncLoading.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SettingsRow), findsOneWidget);
      expect(find.byType(Skeleton), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
