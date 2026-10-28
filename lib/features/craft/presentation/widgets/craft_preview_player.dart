import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/craft/application/craft_preview_controller.dart';
import 'package:enjoy_player/features/craft/presentation/audio_stage_preview_player.dart';

class CraftPreviewPlayer extends StatefulWidget {
  const CraftPreviewPlayer({required this.audioBytes, super.key});

  final Uint8List audioBytes;

  @override
  State<CraftPreviewPlayer> createState() => _CraftPreviewPlayerState();
}

class _CraftPreviewPlayerState extends State<CraftPreviewPlayer> {
  final _controller = CraftPreviewController();

  @override
  void didUpdateWidget(covariant CraftPreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioBytes != widget.audioBytes) {
      _controller.reset(notify: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => AudioStagePreviewPlayer(
        isPlaying: _controller.isPlaying,
        position: _controller.position,
        duration: _controller.duration,
        onToggle: () => unawaited(_controller.toggle(widget.audioBytes)),
        onSeek: (value) => unawaited(_controller.seek(value)),
        fmt: formatDurationHms,
        theme: Theme.of(context),
      ),
    );
  }
}
