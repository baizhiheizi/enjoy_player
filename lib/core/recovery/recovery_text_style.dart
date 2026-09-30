/// Shared mono body style for the two full-screen recovery surfaces.
library;

import 'package:enjoy_player/core/theme/typography.dart';
import 'package:flutter/material.dart';

TextStyle recoveryMonoText(BuildContext context, ColorScheme cs) {
  return enjoyMonoStyle(
    context,
    size: 12,
    weight: FontWeight.w400,
    color: cs.onSurfaceVariant,
  );
}
