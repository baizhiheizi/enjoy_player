/// Root Material app with router + theming.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class EnjoyApp extends ConsumerWidget {
  const EnjoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appPrefs = ref.watch(appPreferencesCtrlProvider);
    final mode = appPrefs.themeMode;
    final light = buildAppTheme(Brightness.light);
    final dark = buildAppTheme(Brightness.dark);

    return AppHotkeysKeyboardListener(
      child: MaterialApp.router(
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
        theme: light,
        darkTheme: dark,
        themeMode: mode,
        locale: appPrefs.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
