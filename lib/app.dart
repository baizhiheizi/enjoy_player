/// Root Material app with router + theming.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/layout/constrained_app_viewport.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class EnjoyApp extends ConsumerStatefulWidget {
  const EnjoyApp({super.key});

  @override
  ConsumerState<EnjoyApp> createState() => _EnjoyAppState();
}

class _EnjoyAppState extends ConsumerState<EnjoyApp> {
  /// Keeps locale/prefs visible while [appPreferencesCtrlProvider] reloads after
  /// auth-scoped DB switches (signed-in), avoiding a full-app loading flash.
  AppPreferencesState? _lastResolvedPrefs;

  MaterialApp _loadingMaterialApp(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      home: const ConstrainedAppViewport(
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }

  MaterialApp _errorMaterialApp(ThemeData theme, Object error) {
    return MaterialApp(
      theme: theme,
      home: ConstrainedAppViewport(
        child: Scaffold(body: Center(child: Text('$error'))),
      ),
    );
  }

  Widget _routerApp({
    required GoRouter router,
    required ThemeData theme,
    required AppPreferencesState prefs,
  }) {
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      theme: theme,
      locale: prefs.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        final viewport = ConstrainedAppViewport(
          child: child ?? const SizedBox.shrink(),
        );
        return isDesktop
            ? AppHotkeysKeyboardListener(child: viewport)
            : viewport;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final prefsAsync = ref.watch(appPreferencesCtrlProvider);
    final theme = buildAppTheme();

    final live = prefsAsync.valueOrNull;
    if (live != null) {
      _lastResolvedPrefs = live;
    }

    final effective = live ?? _lastResolvedPrefs;

    if (prefsAsync.hasError && effective == null) {
      return _errorMaterialApp(theme, prefsAsync.error!);
    }

    if (prefsAsync.isLoading && effective == null) {
      return _loadingMaterialApp(theme);
    }

    return _routerApp(
      router: router,
      theme: theme,
      prefs: effective ?? AppPreferencesState.initial,
    );
  }
}
