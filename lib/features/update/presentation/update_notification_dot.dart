/// Small red notification dot for pending app updates.
library;

import 'package:flutter/material.dart';

/// Compact unread-style indicator used on Profile / Settings entry points.
class UpdateNotificationDot extends StatelessWidget {
  const UpdateNotificationDot({super.key, this.size = 8, this.semanticsLabel});

  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.error,
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: size >= 8 ? 1.5 : 1),
      ),
    );
    final label = semanticsLabel;
    if (label == null || label.isEmpty) return dot;
    return Semantics(label: label, container: true, child: dot);
  }
}
