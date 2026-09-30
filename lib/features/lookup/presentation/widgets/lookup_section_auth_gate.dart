/// Shared auth gate for lookup sheet sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';

/// What the gate should render for the current [AuthCtrl] state. The
/// mapping preserves the pre-#831 `AsyncValue.when` defaults exactly:
/// shimmer for a reload without a previous value but not for a refresh
/// with one, and the callout for **every** terminal error — including one
/// that carries a cached [AuthSignedIn] as its previous value.
enum _AuthGatePhase { loading, error, signedIn, signedOut }

_AuthGatePhase _authGatePhase(AsyncValue<AuthState> auth) {
  if (auth.isLoading && !auth.isRefreshing) return _AuthGatePhase.loading;
  if (auth.hasError) return _AuthGatePhase.error;
  return auth.valueOrNull is AuthSignedIn
      ? _AuthGatePhase.signedIn
      : _AuthGatePhase.signedOut;
}

/// Guards a lookup section body behind the signed-in check.
///
/// Renders [AuthRequiredCallout] (compact) when [authCtrlProvider] is not in the
/// [AuthSignedIn] state — covering signed-out, loading, and the outer error path
/// — so each section widget only has to describe its signed-in body. The shared
/// shimmer is shown while auth is resolving; a failed auth resolution falls back
/// to the same callout as an explicit sign-out, even when the failed refresh
/// still carries a previously signed-in value.
class LookupSectionAuthGate extends ConsumerWidget {
  const LookupSectionAuthGate({
    required this.surface,
    required this.child,
    super.key,
  });

  /// Which lookup surface the callout should attribute the sign-in prompt to.
  final AuthRequiredSurface surface;

  /// Rendered only when the user is [AuthSignedIn].
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(authCtrlProvider.select(_authGatePhase));
    return switch (phase) {
      _AuthGatePhase.loading => const LookupSectionShimmer(),
      _AuthGatePhase.signedIn => child,
      _AuthGatePhase.error => AuthRequiredCallout(
        surface: surface,
        compact: true,
      ),
      _AuthGatePhase.signedOut => AuthRequiredCallout(
        surface: surface,
        compact: true,
      ),
    };
  }
}
