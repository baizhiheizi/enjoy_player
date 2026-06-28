/// Root Material app with router + theming.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/layout/constrained_app_viewport.dart';
import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/core/recovery/recovery_surface.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_deep_link_listener.dart';
import 'package:enjoy_player/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart';
import 'package:enjoy_player/features/update/presentation/update_prompt_host.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class EnjoyApp extends ConsumerStatefulWidget {
  const EnjoyApp({super.key, @visibleForTesting this.themeBuilder});

  /// When set (widget tests only), skips [buildAppTheme] / Google Fonts fetches.
  @visibleForTesting
  final ThemeData Function()? themeBuilder;

  @override
  ConsumerState<EnjoyApp> createState() => _EnjoyAppState();
}

class _EnjoyAppState extends ConsumerState<EnjoyApp> {
  /// Keeps locale/prefs visible while [appPreferencesCtrlProvider] reloads after
  /// auth-scoped DB switches (signed-in), avoiding a full-app loading flash.
  AppPreferencesState? _lastResolvedPrefs;

  MaterialApp _loadingMaterialApp(ThemeData theme) {
    return MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: theme,
      home: const ConstrainedAppViewport(
        child: Scaffold(body: Center(child: SkeletonAppBootstrap())),
      ),
    );
  }

  MaterialApp _errorMaterialApp(
    ThemeData theme,
    Object error,
    StackTrace? stack,
  ) {
    final isDb = isUnrecoverableDatabaseError(error);
    return MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: theme,
      home: isDb
          ? RecoverySurface(error: error, stack: stack)
          : ConstrainedAppViewport(
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
      scaffoldMessengerKey: appScaffoldMessengerKey,
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
        const overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF09090B),
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        );
        final viewport = ConstrainedAppViewport(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: child ?? const SizedBox.shrink(),
          ),
        );
        final hosted = AuthDeepLinkListener(
          child: UpdatePromptHost(child: viewport),
        );
        return isDesktop ? AppHotkeysKeyboardListener(child: hosted) : hosted;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppPreferencesState>>(appPreferencesCtrlProvider, (
      prev,
      next,
    ) {
      final nextPrefs = next.valueOrNull;
      if (nextPrefs == null) return;
      if (identical(nextPrefs, _lastResolvedPrefs)) return;
      setState(() {
        _lastResolvedPrefs = nextPrefs;
      });
    });

    final router = ref.watch(appRouterProvider);
    final prefsAsync = ref.watch(appPreferencesCtrlProvider);
    final theme = widget.themeBuilder?.call() ?? buildAppTheme();

    final live = prefsAsync.valueOrNull;
    final effective = live ?? _lastResolvedPrefs;

    if (prefsAsync.hasError && effective == null) {
      return _errorMaterialApp(theme, prefsAsync.error!, prefsAsync.stackTrace);
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
