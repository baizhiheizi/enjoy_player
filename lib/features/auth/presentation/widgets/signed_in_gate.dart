import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SignedInGate extends ConsumerWidget {
  const SignedInGate({
    required this.surface,
    required this.builder,
    this.loading = const Center(child: CircularProgressIndicator()),
    super.key,
  });

  final AuthRequiredSurface surface;
  final Widget loading;
  final Widget Function(BuildContext context, AuthSignedIn state) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return auth.when(
      data: (state) {
        if (state is AuthSignedIn) return builder(context, state);
        return Center(
          child: AuthRequiredCallout(surface: surface, compact: false),
        );
      },
      loading: () => loading,
      error: (Object error, StackTrace stackTrace) =>
          Center(child: Text(l10n.errorGenericLoadFailed)),
    );
  }
}
