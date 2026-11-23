/// Compact icon buttons safe to mount inside scrollable lists.
library;

import 'package:material_ui/material_ui.dart';

/// Icon button without a [Tooltip] overlay.
///
/// [Tooltip] uses [OverlayPortal], which must not activate while an ancestor
/// [LayoutBuilder] is in [performLayout] (e.g. echo controls inside the
/// transcript [ListView] beside the video [LayoutBuilder]).
class ListSafeIconButton extends StatelessWidget {
  const ListSafeIconButton({
    required this.semanticLabel,
    required this.icon,
    this.onPressed,
    super.key,
  });

  final String semanticLabel;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}
