import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Grabber for modal bottom sheets (36×5 capsule, Aurora).
///
/// Use with [showModalBottomSheet] `showDragHandle: false` and prefer
/// [PaddedSheetDragHandle] for the standard vertical inset above sheet headers.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// [SheetDragHandle] wrapped with the shared vertical padding used on Enjoy
/// sheet chrome (subtitle track picker, pronunciation assessment, …).
class PaddedSheetDragHandle extends StatelessWidget {
  const PaddedSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(top: t.space8 + 2, bottom: t.space12),
      child: const Center(child: SheetDragHandle()),
    );
  }
}
