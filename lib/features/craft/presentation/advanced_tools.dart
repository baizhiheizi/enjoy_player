/// Advanced mode container: responsive two-tool layout.
///
/// Shows `TranslateTool` and `SynthesizeTool` side-by-side on wide screens
/// (≥600px) and stacked on narrow screens. Uses `LayoutBuilder` for
/// responsive breakpoints.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/craft/presentation/synthesize_tool.dart';
import 'package:enjoy_player/features/craft/presentation/translate_tool.dart';

/// Container widget for Advanced mode (Translate + Synthesize tools).
class AdvancedTools extends ConsumerWidget {
  const AdvancedTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TranslateTool()),
              SizedBox(width: 16),
              Expanded(child: SynthesizeTool()),
            ],
          );
        }

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [TranslateTool(), SizedBox(height: 16), SynthesizeTool()],
        );
      },
    );
  }
}
