library;

import 'package:flutter/material.dart';

class LoadingIcon extends StatelessWidget {
  const LoadingIcon({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color,
    this.brightSurface = false,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final bool brightSurface;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        (brightSurface
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary);

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: resolvedColor,
      ),
    );
  }
}
