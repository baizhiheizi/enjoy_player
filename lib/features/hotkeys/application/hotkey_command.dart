/// Command interface for hotkey dispatch (issue #719).
///
/// Each hotkey action owns one [HotkeyCommand] that lives next to the logic
/// it calls (in the feature that executes it). The listener resolves the key
/// event to a binding and runs the first command — in registry order, see
/// `hotkey_commands.dart` — whose [actionId] matches and whose [canExecute]
/// gate passes.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'
    show ProviderListenable;

import 'package:enjoy_player/core/routing/app_router.dart';

/// Provider-read capability shared by [WidgetRef] and [ProviderContainer]:
/// both expose a `read` with this shape, so one context type serves the
/// mounted listener (a `WidgetRef` tear-off) and per-command unit tests (a
/// [ProviderContainer] tear-off).
typedef HotkeyRead = T Function<T>(ProviderListenable<T> provider);

/// Everything a [HotkeyCommand] may touch: a provider reader plus the router
/// keys the listener used to reach directly.
///
/// [AppHotkeysKeyboardListener] is built in `MaterialApp.router`'s `builder`
/// above the `Navigator`, so its own `context` does not include one — commands
/// navigate through [router] / [rootNavigatorState] / [shellNavigatorState],
/// not `Navigator.of` on an arbitrary context.
class HotkeyCtx {
  HotkeyCtx({required HotkeyRead read, this.listenerContext}) : _reader = read;

  final HotkeyRead _reader;

  /// The listener widget's own context (above `MaterialApp.router`'s
  /// `Navigator`). Only for commands that intentionally replicate the
  /// listener's direct context use (e.g. the off-player expand arm). Null in
  /// unit tests that mount no tree.
  final BuildContext? listenerContext;

  T read<T>(ProviderListenable<T> provider) => _reader(provider);

  GoRouter get router => read(appRouterProvider);

  /// Current router path (`goRouter.state.uri.path` in the old chain).
  String get path => router.state.uri.path;

  /// Context of the router's root navigator (null before the first frame).
  BuildContext? get routerNavigatorContext =>
      router.configuration.navigatorKey.currentContext;

  NavigatorState? get rootNavigatorState =>
      router.configuration.navigatorKey.currentState;

  NavigatorState? get shellNavigatorState =>
      enjoyShellNavigatorKey.currentState;
}

/// One hotkey action: its gate and its execution, living next to the logic it
/// calls. New actions are a `HotkeyDefinition` (registry, settings UI,
/// cheatsheet) plus one command here — no listener edits.
abstract class HotkeyCommand {
  const HotkeyCommand();

  /// Matches a `HotkeyDefinition.id` in `hotkey_definitions.dart`.
  String get actionId;

  /// Whether [execute] applies in the current state. Absorbs the gates the
  /// old dispatch if-chain inlined (session presence, route guards, platform
  /// checks). A matched binding whose gate fails does not consume the key —
  /// dispatch keeps scanning (the fall-through semantics of the if-chain).
  bool canExecute(HotkeyCtx ctx);

  /// Side effects. Only called after [canExecute] returned true.
  void execute(HotkeyCtx ctx);
}
