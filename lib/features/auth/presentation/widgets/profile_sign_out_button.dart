/// Confirm-dialog-aware sign-out CTA for the profile screen.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({
    required this.saving,
    required this.onPressed,
    super.key,
  });

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: l10n.authSignOut,
      child: TextButton.icon(
        onPressed: saving ? null : onPressed,
        icon: Icon(Icons.logout_rounded, color: cs.error, size: 20),
        label: Text(
          l10n.authSignOut,
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: cs.error,
        ),
      ),
    );
  }
}
