library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

/// Header-area refresh control for lookup sheet sections (cache bust + refetch).
class LookupRefreshIconButton extends StatelessWidget {
  const LookupRefreshIconButton({
    required this.l10n,
    required this.onPressed,
    super.key,
  });

  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: IconButton(
        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        tooltip: l10n.lookupRefresh,
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 20),
      ),
    );
  }
}
