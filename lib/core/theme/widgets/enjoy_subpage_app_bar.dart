/// Compact push-route app bar — back + title + optional actions.
library;

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    final effectiveLeading =
        leading ??
        (onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
              )
            : null);

    return AppBar(
      automaticallyImplyLeading:
          automaticallyImplyLeading && effectiveLeading == null,
      leading: effectiveLeading,
      title: Text(
        title,
        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
      centerTitle: false,
      titleSpacing: t.space8,
    );
  }
}
