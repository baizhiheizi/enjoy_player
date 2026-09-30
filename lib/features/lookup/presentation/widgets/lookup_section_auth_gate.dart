/// Shared auth gate for lookup sheet sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';

/// Guards a lookup section body behind the signed-in check.
///
/// Renders [AuthRequiredCallout] (compact) when [authCtrlProvider] is not in the
/// [AuthSignedIn] state — covering signed-out, loading, and the outer error path
/// — so each section widget only has to describe its signed-in body. The shared
/// shimmer is shown while auth is resolving; a failed auth resolution falls back
/// to the same callout as an explicit sign-out.
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
    final gate = ref.watch(
      authCtrlProvider.select(
        (a) => (
          loading: a.isLoading && !a.isRefreshing,
          signedIn: a.valueOrNull is AuthSignedIn,
        ),
      ),
    );
    if (gate.loading) return const LookupSectionShimmer();
    if (!gate.signedIn) {
      return AuthRequiredCallout(surface: surface, compact: true);
    }
    return child;
  }
}
