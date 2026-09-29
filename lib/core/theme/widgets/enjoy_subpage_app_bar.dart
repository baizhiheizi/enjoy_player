/// Compact push-route app bar — back chevron + title + optional actions.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Shared chrome for secondary routes (replaces ad-hoc [AppBar] / custom back rows).
class EnjoySubpageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const EnjoySubpageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onBack,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  /// When set, replaces the default back affordance.
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    final effectiveLeading =
        leading ??
        (onBack != null || (automaticallyImplyLeading && canPop)
            ? EnjoyBackButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
              )
            : null);

    return AppBar(
      automaticallyImplyLeading: false,
      leading: effectiveLeading,
      leadingWidth: effectiveLeading == null ? 0 : 52,
      toolbarHeight: 52,
      title: Text(
        title,
        style: tt.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        ...?actions,
        SizedBox(width: t.space8),
      ],
      centerTitle: false,
      titleSpacing: effectiveLeading == null ? t.space20 : t.space4,
    );
  }
}

/// Quiet chevron back control used by subpage chrome and floating player UI.
class EnjoyBackButton extends StatelessWidget {
  const EnjoyBackButton({super.key, required this.onPressed, this.icon});

  final VoidCallback onPressed;

  /// Defaults to a left chevron.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: IconButton(
        icon: Icon(icon ?? EnjoyIcons.back, size: 20),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        color: cs.onSurface,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          fixedSize: const Size(36, 36),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
