/// Centered loading icon and text row for busy button labels in craft tools.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';

class CraftBusyLabel extends StatelessWidget {
  const CraftBusyLabel({
    required this.label,
    this.iconSize = 18,
    this.spacing = 8,
    super.key,
  });

  final String label;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingIcon(size: iconSize),
        SizedBox(width: spacing),
        Text(label),
      ],
    );
  }
}
