/// Express flow orchestrator: switches between capture, rewrite, and audio
/// stages based on [CraftJobState.stage].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';
import 'package:enjoy_player/features/craft/presentation/capture_stage.dart';
import 'package:enjoy_player/features/craft/presentation/rewrite_stage.dart';
import 'package:enjoy_player/features/craft/presentation/audio_stage.dart';

/// Orchestrates the Express flow by showing the right stage widget.
class ExpressFlow extends ConsumerWidget {
  const ExpressFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(craftControllerProvider);

    return SizedBox.expand(
      child: switch (state.stage) {
        CraftStage.capture => const CaptureStage(),
        CraftStage.rewrite => const RewriteStage(),
        CraftStage.audio => const AudioStage(),
        CraftStage.done => const SizedBox.shrink(),
      },
    );
  }
}
